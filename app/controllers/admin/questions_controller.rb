class Admin::QuestionsController < AdminController
  load_and_authorize_resource :test
  load_and_authorize_resource :question, through: :test

  QUESTION_PERMITTED_PARAMS = [
    :content,
    :question_type,
    {answers_attributes: [:id, :content, :correct, :_destroy]}
  ].freeze

  # GET /admin/tests/:test_id/questions/new
  def new
    @question = @test.questions.single_choice.build
    Settings.question.answer_defaults_number.times{@question.answers.build}
  end

  # POST /admin/tests/:test_id/questions
  def create
    if @question.save
      handle_success(t(".success"))
    else
      handle_failure(:new)
    end
  end

  # GET /admin/tests/:test_id/questions/:id
  def show; end

  # GET /admin/tests/:test_id/questions/:id/edit
  def edit; end

  # PATCH/PUT /admin/tests/:test_id/questions/:id
  def update
    if @question.update(question_params)
      handle_success(t(".success"))
    else
      handle_failure(:edit)
    end
  end

  # DELETE /admin/tests/:test_id/questions/:id
  def destroy
    if @question.destroy
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failure")
    end
    redirect_to admin_test_path(@test)
  end

  private

  def handle_success message
    flash[:success] = message
    redirect_to admin_test_path(@test)
  end

  def handle_failure action
    flash.now[:danger] = t(".failure")
    render action, status: :unprocessable_entity
  end

  def question_params
    params.require(:question).permit(
      QUESTION_PERMITTED_PARAMS
    )
  end
end
