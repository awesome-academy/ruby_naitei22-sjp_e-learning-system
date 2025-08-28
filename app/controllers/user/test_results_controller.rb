class User::TestResultsController < User::ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :lesson, through: :course
  load_and_authorize_resource :test_result, through: :lesson
  # GET /user/courses/:course_id/lessons/:lesson_id/test_results/:test_result_id
  def show
    @test_component = @test_result.component
    @test = @test_component.test
    @questions = @test.questions.includes(:answers).order(:id)
    @total_questions = @questions.count
    @user_answers_data = @test_result.user_answers || {}
  end
end
