class Admin::TestsController < AdminController
  before_action :set_test, only: %i(show edit update destroy)

  TEST_PARAMS = [:name, :description, :duration, :max_attempts].freeze

  # GET /admin/tests
  def index
    @tests = Test.newest
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
      flash[:success] = t(".success")
      redirect_to admin_test_path(@test)
    else
      flash[:error] = t(".failure")
      render :new
    end
  end

  # GET /admin/tests/:id/edit
  def edit; end

  # PATCH/PUT /admin/tests/:id
  def update
    if @test.update(test_params)
      flash[:success] = t(".success")
      redirect_to admin_test_path(@test)
    else
      flash[:error] = t(".failure")
      render :edit
    end
  end

  # DELETE /admin/tests/:id
  def destroy
    if @test.destroy
      flash[:success] = t(".success")
    else
      flash[:error] = t(".failure")
    end
    redirect_to admin_tests_url
  end

  private

  def set_test
    @test = Test.find_by(id: params[:id])
    return if @test

    flash[:error] = t(".test_not_found")
    redirect_to admin_tests_path
  end

  def test_params
    params.require(:test).permit(TEST_PARAMS)
  end
end
