class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    return unless user.admin?

    can :manage, :all
    can :access, :admin_dashboard
  end
end
