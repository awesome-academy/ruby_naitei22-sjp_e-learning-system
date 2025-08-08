class TestGradingService
  attr_reader :test_result, :correct_count, :total_questions, :passed, :test

  def initialize test_result
    @test_result = test_result

    @user = @test_result.user
    @test_component = @test_result.component
    @lesson = @test_component.lesson
    @test = @test_component.test
    @questions = @test.questions.includes(:answers).order(:id)

    @total_questions = @questions.count
    @correct_count = 0
    @passed = false
    @final_answers = {}
  end

  def self.call test_result
    new(test_result).execute!
  end

  def execute!
    ActiveRecord::Base.transaction do
      process_and_calculate_score
      update_test_result_record
      update_related_progress if @passed
    end
    self
  end

  private
  def process_and_calculate_score
    saved_answers = @test_result.user_answers || {}

    @questions.each do |question|
      question_id = question.id.to_s
      saved_answer = saved_answers[question_id] || {}
      selected_answer_ids = Array(saved_answer["selected_answer_ids"])
                            .map(&:to_i).compact
      correct_answer_ids = question.answers.where(correct: true).pluck(:id)

      is_correct = (selected_answer_ids.sort == correct_answer_ids.sort)
      @correct_count += 1 if is_correct

      @final_answers[question_id] = {
        "question_id" => question.id,
        "selected_answer_ids" => selected_answer_ids,
        "correct_answer_ids" => correct_answer_ids,
        "is_correct" => is_correct
      }
    end
  end

  def update_test_result_record
    score_percentage = if @total_questions.zero?
                         0
                       else
                         (@correct_count.to_f / @total_questions * 100).round(2)
                       end
    @passed = score_percentage >= Settings.test_pass_percentage

    @test_result.update!(
      user_answers: @final_answers,
      mark: @correct_count,
      status: @passed ? :passed : :failed
    )
  end

  def update_related_progress
    update_user_lesson
    create_missing_user_words
    update_course_progress_if_needed
  end

  def update_user_lesson
    user_lesson = UserLesson.find_or_initialize_by(user: @user, lesson: @lesson)

    max_mark = TestResult.where(
      user: @user,
      component: @test_component
    ).maximum(:mark) || 0

    user_lesson.update!(
      status: :completed,
      completed_at: Time.current,
      grade: [user_lesson.grade.to_i, max_mark].max
    )
  end

  def create_missing_user_words
    word_components = @lesson.components.word.order(:index_in_lesson)
    return if word_components.empty?

    existing_ids = UserWord.where(
      user: @user,
      component_id: word_components.pluck(:id)
    ).pluck(:component_id)

    new_components = word_components.reject{|c| existing_ids.include?(c.id)}
    return if new_components.empty?

    timestamp = Time.current
    new_user_words_data = new_components.map do |component|
      {
        user_id: @user.id,
        component_id: component.id,
        created_at: timestamp,
        updated_at: timestamp
      }
    end

    UserWord.insert_all(new_user_words_data)
  end

  def update_course_progress_if_needed
    user_course = UserCourse.find_by(user: @user, course: @lesson.course)
    return unless user_course

    total_lessons = @lesson.course.lessons.count
    return if total_lessons.zero?

    completed_lessons = UserLesson.joins(:lesson)
                                  .where(user: @user,
                                         status: :completed)
                                  .for_course(@lesson.course)
                                  .count

    completion_ratio = completed_lessons.to_f / total_lessons
    progress_percentage = (completion_ratio * Settings.max_percentage)
                          .round

    new_status = if progress_percentage >= Settings.max_percentage
                   :completed
                 else
                   :in_progress
                 end

    user_course.update!(
      progress: progress_percentage,
      enrolment_status: new_status
    )
  end
end
