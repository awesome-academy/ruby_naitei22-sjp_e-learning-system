class User::UserTestsController < ApplicationController
  before_action :set_lesson, :set_test_component,
                :handle_ongoing_test, :handle_expired_test,
                :check_attempts_limit,
                only: %i(create)
  before_action :set_test_result, :check_authorization, only: %i(edit update)

  def create
    # Create new test attempt
    @current_attempt = @attempt_count + 1

    @test_result = TestResult.create!(
      user: current_user,
      component: @test_component,
      attempt_number: @current_attempt,
      user_answers: {},
      mark: 0,
      status: :failed,
      submitted: false
    )

    duration = @test_component.test.duration.minutes
    GradeTestJob.set(wait_until: duration.from_now)
                .perform_later(@test_result.id)
    redirect_to edit_user_lesson_user_test_path(@lesson, @test_result)
  end

  # GET /user/lessons/:lesson_id/user_tests/:id/edit
  def edit
    @test_component = @test_result.component
    @test = @test_component.test
    @lesson = @test_component.lesson
    @course = @lesson.course
    @questions = @test.questions.includes(:answers).order(:id)
    @total_questions = @questions.count
    @current_attempt = @test_result.attempt_number
    @remaining_attempts = @test.max_attempts - (@current_attempt - 1)

    # Calculate remaining time
    @remaining_time = calculate_remaining_time

    # Check if test has expired
    return unless @remaining_time <= 0

    handle_final_submission
    nil
  end

  # PATCH/PUT /user/lessons/:lesson_id/user_tests/:id
  def update
    # Check if test has expired before processing
    if test_expired?
      handle_final_submission
      return
    end

    # Handle both save_draft and submit actions
    if params[:commit] == Settings.commit.save_draft ||
       params[:save_draft] == Settings.commit.true_value
      handle_save_draft
    else
      handle_final_submission
    end
  rescue StandardError => e
    handle_submission_error(e)
  end

  private

  def collect_current_answers
    @test_component = @test_result.component
    @test = @test_component.test
    @questions = @test.questions.includes(:answers).order(:id)

    current_answers = {}

    @questions.each do |question|
      question_id = question.id.to_s
      selected_answer_ids = Array(params[:answers]&.[](question_id))
                            .map(&:to_i).compact

      # Save answers without validation for draft
      current_answers[question_id] = {
        "question_id" => question.id,
        "selected_answer_ids" => selected_answer_ids,
        "is_draft" => true
      }
    end

    current_answers
  end

  def handle_save_draft
    # Save current answers as draft without finalizing the test
    draft_answers = collect_current_answers

    @test_result.update!(user_answers: draft_answers)
    @test_component = @test_result.component
    @lesson = @test_component.lesson

    flash[:success] = t(".draft_saved")
    redirect_to edit_user_lesson_user_test_path(@lesson, @test_result)
  end

  def handle_final_submission
    grading_service = TestGradingService.call(@test_result)
    @test_result.update!(submitted: true)
    set_flash_message(grading_service)

    lesson = @test_result.component.lesson
    course = lesson.course
    redirect_to user_course_lesson_path(course, lesson), status: :see_other
  end

  def set_lesson
    @lesson = Lesson.find_by(id: params[:lesson_id])
    return if @lesson

    flash[:danger] = t(".error.lesson_not_found")
    redirect_to user_courses_path
  end

  def set_test_component
    @course = @lesson.course
    @test_component = @lesson.components
                             .test
                             .includes(test: {questions: :answers})
                             .first
    unless @test_component
      flash[:danger] = t(".error.test_not_found")
      redirect_to user_course_lesson_path(@course, @lesson)
      return
    end
    @test = @test_component&.test
    @attempt_count = TestResult.where(
      user: current_user,
      component: @test_component
    ).count
  end

  def check_attempts_limit
    return if @attempt_count < @test.max_attempts

    flash[:danger] = t(".error.max_attempts_reached",
                       max_attempts: @test.max_attempts)
    redirect_to user_course_lesson_path(@course, @lesson)
  end

  def set_test_result
    @test_result = TestResult.find_by(id: params[:id])
    return if @test_result

    flash[:danger] = t(".error.test_result_not_found")
    redirect_to user_course_lesson_path(@lesson.course, @lesson)
  end

  def check_authorization
    return if @test_result.user == current_user

    flash[:danger] = t(".error.unauthorized_access")
    redirect_to root_path
  end

  def handle_ongoing_test
    ongoing_test = TestResult.where(
      user: current_user,
      component: @test_component,
      submitted: false
    ).where("created_at > ?",
            Time.current - @test.duration.minutes).order(:created_at).last
    return if ongoing_test.blank?

    flash[:info] = t(".continuing_ongoing_test")
    redirect_to edit_user_lesson_user_test_path(@lesson, ongoing_test)
  end

  def handle_expired_test
    ongoing_test = TestResult.where(
      user: current_user,
      component: @test_component,
      submitted: false
    ).where("created_at <= ?", Time.current - @test.duration.minutes)
                             .order(:created_at).last

    return if ongoing_test.blank?

    TestGradingService.call(ongoing_test)
    ongoing_test.update!(submitted: true)
    flash[:info] = t(".error.test_auto_submitted")

    redirect_to user_course_lesson_path(@lesson.course, @lesson)
  end

  def calculate_remaining_time
    elapsed_time = Time.current - @test_result.created_at
    @test_component = @test_result.component
    @test = @test_component.test
    total_time_allowed = @test.duration.minutes

    remaining_seconds = total_time_allowed - elapsed_time
    remaining_seconds.positive? ? remaining_seconds.to_i : 0
  end

  def test_expired?
    calculate_remaining_time <= 0
  end

  def set_flash_message grading_service
    if grading_service.passed
      flash[:notice] = t(".passed",
                         score: grading_service.correct_count,
                         total: grading_service.total_questions)
    else
      remaining_attempts = grading_service.test.max_attempts -
                           @test_result.attempt_number
      flash[:notice] = t(".failed",
                         score: grading_service.correct_count,
                         total: grading_service.total_questions,
                         remaining_attempts:)
    end
  end

  def handle_submission_error error
    flash[:danger] = error_message_for(error)
    render :edit
  end

  def error_message_for error
    case error
    when ActiveRecord::RecordInvalid
      t(".error.validation_failed",
        errors: error.record.errors.full_messages.join(", "))
    when ActiveRecord::Rollback
      error.message.presence || t(".error.rollback_failed")
    else
      Rails.logger.error "Test submission error: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")
      t(".error.unexpected")
    end
  end
end
