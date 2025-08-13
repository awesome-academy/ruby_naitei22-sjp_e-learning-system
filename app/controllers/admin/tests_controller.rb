class Admin::TestsController < AdminController
  include Pagy::Backend
  before_action :set_test, only: %i(show update destroy edit)

  # GET /admin/tests
  def index
    @pagy, @tests = pagy(
      Test.by_name(params[:search]).recent,
      items: Settings.test.page_number
    )
  end

  # GET /admin/tests/:id
  def show
    @questions = @test.questions.includes(:answers)
  end

  # GET /admin/tests/new
  def new
    @test = Test.new
  end

  # POST /admin/tests
  def create
    @test = Test.new(test_params)

    if @test.save
      flash[:success] = t(".create_success")
      redirect_to admin_test_path(@test)
    else
      flash.now[:danger] = t(".create_failed")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/tests/:id/edit
  def edit; end

  # PATCH/PUT /admin/tests/:id
  def update
    if @test.update(test_params)
      flash[:success] = t(".update_success")
      redirect_to admin_test_path(@test)
    else
      flash.now[:danger] = t(".update_failed")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/tests/:id
  def destroy
    if @test.destroy
      flash[:success] = t(".delete_success")
      redirect_to admin_tests_path
    else
      flash[:danger] = t(".delete_failed")
      redirect_to admin_test_path(@test)
    end
  end

  private

  def set_test
    @test = Test.find_by(id: params[:id])
    return if @test

    flash[:danger] = t(".not_found")
    redirect_to admin_tests_path
  end

  def test_params
    params.require(:test).permit(Test::TEST_PERMITTED)
  end
end
