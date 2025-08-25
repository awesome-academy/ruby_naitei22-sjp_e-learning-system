class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    case user.role
    when "admin"
      admin_access user
    when "user"
      user_access user
    end
  end

  private

  def admin_access user
    can :access, :admin_dashboard
    can :manage, Answer
    can :manage, Question
    can :manage, Test
    can :manage, Lesson
    can :manage, Course
    can :manage, Word
    can :manage, UserCourse
    can [:show, :edit, :update], User, id: user.id
  end

  def user_access user
    can :access, :user_area
    course_access(user)
    lesson_access(user)
    test_access(user)
    word_access
    profile_access(user)
  end

  def profile_access user
    can [:show, :edit, :update], User, id: user.id
  end

  def word_access
    can :read, Word
  end

  def test_access user
    can [:read, :update], TestResult, user_id: user.id
  end

  def lesson_access user
    can [:show, :study, :test_history], Lesson do |lesson|
      lesson.course.user_courses.exists?(user_id: user.id,
                                         enrolment_status: [:in_progress,
                                                            :completed])
    end
  end

  def course_access user
    can :enroll, Course
    can :start, Course do |course|
      user.user_courses.exists?(course_id: course.id,
                                enrolment_status: :approved)
    end
    can :show, Course do |course|
      user.user_courses.exists?(course_id: course.id,
                                enrolment_status: [:in_progress, :completed])
    end
  end
end
