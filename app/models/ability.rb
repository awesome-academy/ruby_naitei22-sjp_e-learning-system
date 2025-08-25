class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new
    if user.admin?
      can :access, :admin_namespace
      can :manage, :all
      cannot :access, :user_namespace
    elsif user.user?
      can :access, :user_namespace
      can :manage, :all
      cannot :access, :admin_namespace
    else
      can :manage, Course
    end
  end
end
