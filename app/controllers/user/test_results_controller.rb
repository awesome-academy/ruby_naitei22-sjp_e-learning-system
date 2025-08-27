class User::TestResultsController < User::ApplicationController
  load_and_authorize_resource :course
  load_and_authorize_resource :lesson, through: :course
  load_and_authorize_resource :test_result
  before_action :check_authorization, only: %i(show)
  # GET /user/courses/:course_id/lessons/:lesson_id/test_results/:test_result_id
  def show
    @test_component = @test_result.component
    @test = @test_component.test
    @questions = @test.questions.includes(:answers).order(:id)
    @total_questions = @questions.count
    @user_answers_data = @test_result.user_answers || {}
  end

  private

  def check_authorization
    return if @test_result.user == current_user

    flash[:danger] = t(".error.unauthorized_access")
    redirect_to root_path
  end
end
