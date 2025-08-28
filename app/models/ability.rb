class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new
    if user.admin?
      can :access, :admin_namespace
      cannot :access, :user_namespace
      can :manage, :all
    elsif user.user?
      can :access, :user_namespace
      cannot :access, :admin_namespace
      user_abilities(user)
    else
      can :index, Course
    end
  end

  private

  def user_abilities user
    user_courses_abilities(user)
    user_lessons_abilities(user)
    user_test_results_abilities(user)
    user_words_abilities
    user_profile_abilities(user)
  end

  def user_courses_abilities user
    can :enroll, Course
    can :start, Course do |course|
      user.user_courses.exists?(course_id: course.id,
                                enrolment_status: :approved)
    end
    can :show, Course do |course|
      user.user_courses.exists?(course_id: course.id,
                                enrolment_status: %i(in_progress completed))
    end
  end

  def user_lessons_abilities user
    can %i(show study test_history create_user_test), Lesson do |lesson|
      lesson.course.user_courses.exists?(user_id: user.id,
                                         enrolment_status: %i(in_progress
completed))
    end
  end

  def user_test_results_abilities user
    can %i(show edit update), TestResult, user_id: user.id
  end

  def user_words_abilities
    can :index, Word
  end

  def user_profile_abilities user
    can %i(show edit update), User, id: user.id
  end
end
