class User::CoursesController < User::ApplicationController
  skip_before_action :logged_in_user, only: %i(index)
  skip_before_action :ensure_user_role, only: %i(index)
  before_action :set_course, only: %i(show enroll start)
  before_action :check_enrolled, only: %i(enroll)
  before_action :set_user_course, only: %i(show start)
  before_action :set_lessons, :set_progress_data, only: %i(show)
  before_action :ensure_enrolment_approved, only: %i(start)

  # GET user/courses
  def index
    @pagy, @courses = pagy Course.recent.with_users.with_attached_thumbnail,
                           limit: Settings.page_6
    @user_courses_map = current_user&.user_courses&.index_by(&:course_id)
  end

  # GET user/courses/:id
  def show; end

  # POST user/courses/:id/enroll
  def enroll
    @user_course = UserCourse.new(
      user_id: current_user.id,
      course_id: @course.id,
      enrolment_status: 0
    )

    if @user_course.save
      flash[:success] = t(".success_enrolled")
    else
      flash[:danger] = t(".failed_enroll")
    end
    redirect_to user_courses_path, status: :see_other
  end

  # PATCH user/courses/:id/start
  def start
    if update_course_progress
      flash[:success] = t(".success")
      redirect_to user_course_path(@course)
    else
      flash[:danger] = t(".failed")
      redirect_to user_courses_path, status: :see_other
    end
  end

  private

  def check_enrolled
    return unless current_user.user_courses.exists?(course_id: @course.id)

    flash[:warning] = t(".already_enrolled")
    redirect_to user_courses_path, status: :see_other
  end

  def set_course
    @course = Course.find_by(id: params[:id])
    return if @course

    flash[:danger] = t(".error.course_not_found")
    redirect_to root_path
  end

  def set_user_course
    @user_course = current_user.user_courses.find_by(course_id: @course.id)

    return if @user_course.present? && !@user_course.pending?

    flash[:danger] = t(".error.not_enrolled")
    redirect_to user_courses_path
  end

  def set_lessons
    @lessons = @course.lessons.order(:position)
    @total_lessons = @lessons.count
    @learners_count = @course.user_courses.distinct.count(:user_id)
    @duration = @course.duration
  end

  def set_progress_data
    return set_empty_progress unless current_user

    lesson_ids = @lessons.pluck(:id)
    @user_lessons = current_user.user_lessons.where(lesson_id: lesson_ids)
    @completed_count = @user_lessons.where(status: 1).count
    @progress = calculate_progress
  end

  def set_empty_progress
    @user_lessons = %i()
    @completed_count = 0
    @progress = 0
  end

  def calculate_progress
    return 0 if @total_lessons.zero?

    ((@completed_count.to_f / @total_lessons) * 100).round
  end

  def ensure_enrolment_approved
    return if @user_course&.approved?

    flash[:danger] = t(".invalid_status")
    redirect_to user_courses_path, status: :see_other
  end

  def update_course_progress
    start_date = Date.current
    end_date   = start_date + @course.duration.days

    @user_course.update(
      enrolment_status: :in_progress,
      start_date:,
      end_date:
    )
  end
end
