class Admin::CoursesController < AdminController
  include Pagy::Backend

  load_and_authorize_resource

  # GET /admin/courses
  def index
    @pagy, @courses = pagy(
      Course.includes(Course::COURSE_PRELOAD)
            .recent
            .by_title(params[:search]),
      limit: Settings.course.page_number
    )
  end

  # GET /admin/courses/:id
  def show; end

  # GET /admin/courses/new
  def new
    @admin_users = User.admin
  end

  # POST /admin/courses
  def create
    if @course.save
      flash[:success] = t(".create_success")
      redirect_to admin_course_path(@course)
    else
      @admin_users = User.admin
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/courses/:id/edit
  def edit
    @admin_users = User.admin
    @course.course_admin_ids = @course.admins.pluck(:id)
  end

  # PATCH/PUT /admin/courses/:id
  def update
    if @course.update(course_params)
      flash[:success] = t(".update_success")
      redirect_to admin_course_path(@course)
    else
      @admin_users = User.admin
      @course.course_admin_ids = params.dig(:course, :course_admin_ids)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/courses/:id
  def destroy
    if @course.destroy
      flash[:success] = t(".delete_success")
    else
      flash[:error] = t(".delete_failed")
    end
    redirect_to admin_courses_path
  end

  private

  def course_params
    params.require(:course)
          .permit(Course::COURSE_PERMITTED)
          .merge(creator: current_user)
  end
end
