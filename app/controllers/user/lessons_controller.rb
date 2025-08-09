class User::LessonsController < User::ApplicationController
  before_action :set_course, only: %i(show)
  before_action :set_lesson,
                only: %i(show study take_test submit_test)
  before_action :check_word_empty, only: %i(study)
  before_action :set_test_component, only: %i(take_test submit_test)
  before_action :check_test_exists, only: %i(take_test submit_test)
  before_action :set_test_data, only: %i(take_test submit_test)
  before_action :check_attempts_limit, only: %i(take_test)

  # GET user/courses/:course_id/lessons/:id
  def show
    @paragraphs = @lesson.components
                         .paragraph
                         .order(:index_in_lesson)
    @user_lesson = UserLesson.find_by(user: current_user, lesson: @lesson)
    @lesson_test = Component.find_by(lesson: @lesson, component_type: "test")
    @number_of_attempts = TestResult.where(user: current_user,
                                           component: @lesson_test).count
  end

  # GET user/courses/:course_id/lessons/:id/study
  def study
    @course = @lesson.course
    set_word_components
    set_current_word_data
  end

  # GET user/courses/:course_id/lessons/:id/take_test
  def take_test
    @current_attempt = @attempt_count + 1
    @remaining_attempts = @test.max_attempts - @attempt_count
  end

  # POST user/courses/:course_id/lessons/:id/submit_test
  def submit_test
    ActiveRecord::Base.transaction do
      process_test_submission
      handle_successful_submission
    end

    redirect_to user_course_lesson_path(@course, @lesson), status: :see_other
  rescue StandardError => e
    handle_submission_error(e)
  end

  private

  def set_course
    @course = Course.find_by(id: params[:course_id])
    return if @course

    flash[:danger] = t(".error.course_not_found")
    redirect_to root_path
  end

  def set_lesson
    @lesson = Lesson.find_by(id: params[:id])
    return if @lesson

    flash[:danger] = t(".error.lesson_not_found")
    redirect_to user_course_path(@course)
  end

  def check_word_empty
    return if @lesson.components.word.exists?

    flash[:danger] = t(".error.no_words_found")
    redirect_to user_course_lesson_path(@lesson.course, @lesson)
  end

  def set_word_components
    @word_components = @lesson.components.includes(:word)
                              .word
                              .sorted_by_index
  end

  def set_current_word_data
    @total_words = @word_components.length
    @current_index = word_index_param.clamp(0, @total_words - 1)
    @current_component = @word_components[@current_index]
    @current_word = @current_component&.word
    @current_position = @current_index + 1
    @has_previous = @current_index.positive?
    @has_next = @current_index < (@total_words - 1)
    @previous_index = @has_previous ? @current_index : nil
    @next_index = @has_next ? @current_index + 2 : nil
  end

  def word_index_param
    params[:word_index].to_i - 1
  end

  def set_test_component
    @course = @lesson.course
    @test_component = @lesson.components
                             .test
                             .includes(test: {questions: :answers})
                             .first
  end

  def check_test_exists
    return if @test_component.present?

    flash[:danger] = t(".error.test_not_found")
    redirect_to user_course_lesson_path(@course, @lesson)
  end

  def set_test_data
    @test = @test_component.test
    @questions = @test.questions.includes(:answers).order(:id)
    @attempt_count = TestResult.where(
      user: current_user,
      component: @test_component
    ).count
  end

  def check_attempts_limit
    return if @attempt_count < @test.max_attempts

    flash[:danger] =
      t(".error.max_attempts_reached", max_attempts: @test.max_attempts)
    redirect_to user_course_lesson_path(@course, @lesson)
  end

  def process_test_submission
    @user_answers = {}
    @correct_count = 0
    @total_questions = @questions.count

    @questions.each do |question|
      process_question(question)
    end

    @score_percentage = calculate_score_percentage
    @passed = @score_percentage >= Settings.test_pass_percentage
  end

  def process_question question
    question_id = question.id.to_s
    selected_answer_ids = Array(params[:answers]&.[](question_id))
                          .map(&:to_i).compact
    correct_answer_ids = question.answers.where(correct: true).pluck(:id)

    validate_single_choice_question(question, selected_answer_ids)

    is_correct = (selected_answer_ids.sort == correct_answer_ids.sort)
    @correct_count += 1 if is_correct

    @user_answers[question_id] = {
      "question_id" => question.id,
      "selected_answer_ids" => selected_answer_ids,
      "correct_answer_ids" => correct_answer_ids,
      "is_correct" => is_correct
    }
  end

  def validate_single_choice_question question, selected_answer_ids
    return unless
      question.question_type == "single_choice" &&
      selected_answer_ids.length > 1

    raise ActiveRecord::Rollback, t(".error.multiple_answers_selected")
  end

  def calculate_score_percentage
    (@correct_count.to_f / @total_questions * 100).round(2)
  end

  def handle_successful_submission
    create_test_result
    update_lesson_completion if @passed
    update_course_progress if @passed
    set_flash_message
  end

  def create_test_result
    TestResult.create!(
      user: current_user,
      component: @test_component,
      attempt_number: @attempt_count + 1,
      user_answers: @user_answers,
      mark: @correct_count,
      status: @passed ? "passed" : "failed"
    )
  end

  def update_lesson_completion
    update_lesson_completion_transactional
  end

  def update_course_progress
    update_course_progress_if_needed
  end

  def set_flash_message
    if @passed
      flash[:notice] =
        t(".passed", score: @correct_count, total: @total_questions)
    else
      remaining_attempts = @test.max_attempts - @attempt_count - 1
      flash[:notice] =
        t(".failed", score: @correct_count, total: @total_questions,
remaining_attempts:)
    end
  end

  def handle_submission_error error
    flash[:danger] = error_message_for(error)
    render :take_test
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

  def update_lesson_completion_transactional
    user_lesson = find_or_initialize_user_lesson
    update_user_lesson(user_lesson)
    create_missing_user_words
  end

  def find_or_initialize_user_lesson
    UserLesson.find_or_initialize_by(user: current_user,
                                     lesson: @lesson).tap do |ul|
      ul.grade ||= 0
    end
  end

  def update_user_lesson user_lesson
    max_mark = TestResult.where(
      user: current_user,
      component: @lesson.components.test
    ).maximum(:mark) || 0

    user_lesson.update!(
      status: "completed",
      completed_at: Time.current,
      grade: max_mark
    )
  end

  def create_missing_user_words
    word_components = @lesson.components.word.sorted_by_index
    return if word_components.empty?

    existing_ids = UserWord.where(
      user: current_user,
      component_id: word_components.pluck(:id)
    ).pluck(:component_id)

    new_components = word_components.reject{|c| existing_ids.include?(c.id)}
    return if new_components.empty?

    timestamp = Time.current
    new_user_words_data = new_components.map do |component|
      {
        user_id: current_user.id,
        component_id: component.id,
        created_at: timestamp,
        updated_at: timestamp
      }
    end

    UserWord.insert_all(new_user_words_data)
  end

  def update_course_progress_if_needed
    user_course = UserCourse.find_by(user: current_user, course: @lesson.course)
    return unless user_course

    total_lessons = @lesson.course.lessons.count
    completed_lessons = UserLesson.joins(:lesson)
                                  .where(user: current_user,
                                         lessons: {course: @lesson.course},
                                         status: "completed")
                                  .count

    progress_percentage = (completed_lessons.to_f / total_lessons * 100).round

    user_course.update!(
      progress: progress_percentage,
      enrolment_status: progress_percentage >= 100 ? "completed" : "in_progress"
    )
  end
end
