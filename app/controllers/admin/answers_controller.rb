# app/controllers/admin/answers_controller.rb
class Admin::AnswersController < AdminController
  load_and_authorize_resource :test, parent: true, only: %i(new create destroy)
  load_and_authorize_resource :question, through: :test, singleton: true
  load_and_authorize_resource through: :question

  ANSWER_PARAMS = [:content, :correct].freeze

  # GET /admin/tests/:test_id/questions/:question_id/answers/new
  def new
    render partial: "answers/form", locals: {answer: @answer}
  end

  # POST /admin/tests/:test_id/questions/:question_id/answers
  def create
    @answer.assign_attributes(answer_params)
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

  def answer_params
    params.require(:answer).permit(ANSWER_PARAMS)
  end
end
