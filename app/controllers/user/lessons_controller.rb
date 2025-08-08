class User::LessonsController < User::ApplicationController
  before_action :set_course, only: %i(show test_history)
  before_action :set_lesson,
                only: %i(show study test_history)
  before_action :set_user_lesson, only: %i(test_history)
  before_action :set_test_component, only: %i(test_history)
  before_action :check_word_empty, only: %i(study)

  # GET user/courses/:course_id/lessons/:id
  def show
    @paragraphs = @lesson.components
                         .paragraph
                         .order(:index_in_lesson)
    @user_lesson = UserLesson.find_by(user: current_user, lesson: @lesson)
    @lesson_test = Component.find_by(lesson: @lesson, component_type: "test")
    @number_of_attempts = TestResult.where(user: current_user,
                                           component: @lesson_test).count
    @attempt_left = @lesson_test.test.max_attempts - @number_of_attempts
  end

  # GET user/courses/:course_id/lessons/:id/study
  def study
    @course = @lesson.course
    set_word_components
    set_current_word_data
  end

  # GET user/courses/:course_id/lessons/:id/test_history
  def test_history
    # Get all test attempts for this user and test component
    @test_results = TestResult.where(
      user: current_user,
      component: @test_component
    ).order(:attempt_number)

    # Get total questions count
    @total_questions = @test_component.test.questions.count

    # Get the status from user_lesson (pass/fail)
    @lesson_status = @user_lesson&.status

    # Get the best grade from user_lesson
    @best_grade = @user_lesson&.grade || 0

    @number_of_attempts = @test_results.count
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

  def set_test_component
    @test_component = @lesson.components.test.first
    return if @test_component

    flash[:danger] = t(".error.test_not_found")
    redirect_to user_course_lesson_path(@course, @lesson)
    nil
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

  def set_user_lesson
    @user_lesson = UserLesson.find_by(user: current_user, lesson: @lesson)
  end
end
