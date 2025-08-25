class User::TestResultsController < User::ApplicationController
  load_and_authorize_resource :course, Course.name
  load_and_authorize_resource :lesson, through: :course, shallow: true
  before_action :set_test_result, only: %i(show)

  # GET /user/courses/:course_id/lessons/:lesson_id/test_results/:id
  def show
    @test_component = @test_result.component
    @test = @test_component.test
    @questions = @test.questions.includes(:answers).order(:id)
    @total_questions = @questions.count
    @user_answers_data = @test_result.user_answers || {}
  end

  private

  def set_test_result
    @test_result = TestResult.find_by(id: params[:id])
    return if @test_result

    flash[:danger] = t(".error.test_result_not_found")
    redirect_to user_course_lesson_path(@course, @lesson)
  end
end
