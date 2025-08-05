class Admin::QuestionsController < AdminController
  before_action :set_test
  before_action :set_question, only: %i(edit update destroy)

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
    @question = @test.questions.build(question_params)

    if @question.save
      flash[:success] = t(".success")
      redirect_to admin_test_path(@test)
    else
      flash[:error] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/tests/:test_id/questions/:id
  def show; end

  # GET /admin/tests/:test_id/questions/:id/edit
  def edit; end

  # PATCH/PUT /admin/tests/:test_id/questions/:id
  def update
    if @question.update(question_params)
      flash[:success] = t(".success")
      redirect_to admin_test_path(@test)
    else
      flash[:error] = t(".failure")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/tests/:test_id/questions/:id
  def destroy
    if @question.destroy
      flash[:success] = t(".success")
    else
      flash[:error] = t(".failure")
    end
    redirect_to admin_test_path(@test)
  end

  private

  def set_test
    @test = Test.find_by(id: params[:test_id])
  end

  def set_question
    @question = @test.questions.find_by(id: params[:id])
  end

  def question_params
    params.require(:question).permit(
      QUESTION_PERMITTED_PARAMS
    )
  end
end
