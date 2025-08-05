# app/controllers/admin/answers_controller.rb
class Admin::AnswersController < AdminController
  before_action :set_test
  before_action :set_question
  before_action :set_answer, only: %i(destroy)

  ANSWER_PARAMS = [:content, :correct].freeze

  # GET /admin/tests/:test_id/questions/:question_id/answers/new
  def new
    @answer = @question.answers.build
    render partial: "answers/form", locals: {answer: @answer}
  end

  # POST /admin/tests/:test_id/questions/:question_id/answers
  def create
    @answer = @question.answers.build(answer_params)
    if @answer.save
      flash[:success] = t(".create.success")
    else
      flash[:error] = t(".create.failure")
    end
    redirect_to admin_test_question_path(@test, @question)
  end

  # DELETE /admin/tests/:test_id/questions/:question_id/answers/:id
  def destroy
    if @answer.destroy
      flash[:success] = t(".destroy.success")
    else
      flash[:error] = t(".destroy.failure")
    end
    redirect_to admin_test_question_path(@test, @question)
  end

  private

  def set_test
    @test = Test.find_by(id: params[:test_id])
    return if @test

    flash[:error] = t(".test_not_found")
    redirect_to admin_tests_path and return
  end

  def set_question
    @question = @test.questions.find_by(id: params[:question_id])
    return if @question

    flash[:error] = t(".question_not_found")
    redirect_to admin_test_path(@test)
  end

  def set_answer
    @answer = @question.answers.find_by(id: params[:id])
    return if @answer

    flash[:error] = t(".answer_not_found")
    redirect_to admin_test_question_path(@test, @question)
  end

  def answer_params
    params.require(:answer).permit(ANSWER_PARAMS)
  end
end
