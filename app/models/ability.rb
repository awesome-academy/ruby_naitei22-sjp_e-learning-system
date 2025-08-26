# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    if user.admin?
      admin_abilities user
    elsif user.user?
      user_abilities user
    end
  end

  private

  def admin_abilities user
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

  def user_abilities user
    can :access, :user_area
    user_course_abilities(user)
    user_lesson_abilities(user)
    user_test_abilities(user)
    user_word_abilities
    user_profile_abilities(user)
  end

  def user_course_abilities user
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

  def user_lesson_abilities user
    can [:show, :study, :test_history], Lesson do |lesson|
      lesson.course.user_courses.exists?(user_id: user.id,
                                         enrolment_status: [:in_progress,
                                                            :completed])
    end
  end

  def user_test_abilities user
    can [:read, :update], TestResult, user_id: user.id
  end

  def user_word_abilities
    can :read, Word
  end

  def user_profile_abilities user
    can [:show, :edit, :update], User, id: user.id
  end
end
