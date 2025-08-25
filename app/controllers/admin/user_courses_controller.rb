class Admin::UserCoursesController < AdminController
  load_and_authorize_resource

  before_action :ensure_selection_present, :set_selected_user_courses,
                only: %i(approve_selected reject_selected)
  before_action :set_approvable_and_invalid_courses, only: %i(approve_selected)
  before_action :set_rejectable_and_invalid_courses, only: %i(reject_selected)
  respond_to :html, :json

  FILTER_KEYS = %i(course status registered_from expiration_date page).freeze

  # GET /admin/user_courses
  def index
    @user_courses = filter_user_courses
    @pagy, @user_courses = pagy(@user_courses)
    @courses = Course.all
  end

  # PATCH /admin/user_courses/:id/approve
  def approve
    if @user_course.approved!
      flash[:success] = t(".approve_success")
    else
      flash[:danger] = t(".approve_failed")
    end

    redirect_index_with_filters
  rescue StandardError => e
    Rails.logger.error(t(".log_error", error: e.message))
    flash[:danger] = t(".approve_failed")
    redirect_index_with_filters
  end

  # GET /admin/user_courses/:id/reject_form
  def reject_form
    respond_modal_with @user_course
  end

  # PATCH /admin/user_courses/:id/reject
  def reject
    @user_course.update!(reason: params[:reason].presence,
                         enrolment_status: :rejected)

    flash[:success] = t(".reject_success")

    redirect_index_with_filters
  rescue StandardError => e
    Rails.logger.error(t(".log_error", error: e.message))
    flash[:danger] = t(".reject_failed")
    redirect_index_with_filters
  end

  # POST /admin/user_courses/approve_selected
  def approve_selected
    if @invalid_courses.exists?
      flash[:danger] = t(".invalid_status_error")
    elsif @approvable_courses.empty?
      flash[:danger] = t(".no_approvable_courses")
    else
      @approvable_courses.update_all(enrolment_status: :approved)
      flash[:success] =
        t(".approve_selected_success", count: @approvable_courses.count)
    end

    redirect_index_with_filters
  end

  # POST /admin/user_courses/reject_selected
  def reject_selected
    if @invalid_courses.exists?
      flash[:danger] = t(".invalid_status_for_reject_error")
    elsif @rejectable_courses.empty?
      flash[:warning] = t(".no_rejectable_courses")
    else
      @rejectable_courses.update_all(enrolment_status: :rejected)
      flash[:success] =
        t(".reject_selected_success", count: @rejectable_courses.count)
    end

    redirect_index_with_filters
  end

  # GET /admin/user_courses/:id/reject_detail
  def reject_detail
    respond_modal_with @user_course
  end

  # GET /admin/user_courses/:id/profile
  def profile
    @user = @user_course.user
    @course = @user_course.course
    @lessons = load_lessons
    @user_lessons = load_user_lessons
    @test_results = load_test_results
    @progress_percentage = calculate_progress_percentage
  end

  private

  def ensure_selection_present
    return if params[:user_course_ids].present?

    flash[:danger] = t(".no_selection")
    redirect_to admin_user_courses_path
  end

  def set_selected_user_courses
    @selected_user_courses = UserCourse.where(id: params[:user_course_ids])
  end

  def set_approvable_and_invalid_courses
    @approvable_courses = @selected_user_courses.approvable
    @invalid_courses = @selected_user_courses.invalid_for_approve
  end

  def set_rejectable_and_invalid_courses
    @rejectable_courses = @selected_user_courses.rejectable
    @invalid_courses = @selected_user_courses.invalid_for_reject
  end

  def preserved_filters
    filters = params.slice(*FILTER_KEYS).permit(*FILTER_KEYS)
    return filters if filters.present?

    if request.referer.present?
      query = Rack::Utils.parse_nested_query(
        URI.parse(request.referer).query || ""
      )
      query.symbolize_keys.slice(*FILTER_KEYS)
    else
      {}
    end
  end

  def redirect_index_with_filters
    redirect_to admin_user_courses_path(preserved_filters)
  end

  def filter_user_courses
    UserCourse.includes(UserCourse::ASSOCIATIONS)
              .by_course(params[:course])
              .by_status(params[:status])
              .registered_from(params[:registered_from])
              .expiration_date(params[:expiration_date])
              .order(created_at: :desc)
  end

  def load_lessons
    @course.lessons.with_user_lessons_for(@user)
  end

  def load_user_lessons
    UserLesson.for_user_and_course(@user, @course)
  end

  def load_test_results
    TestResult.for_user_and_course(@user, @course)
  end

  def calculate_progress_percentage
    @course.progress_percentage_for_user(@user)
  end
end
