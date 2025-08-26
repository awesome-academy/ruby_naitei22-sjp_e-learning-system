class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    case user.role
    when "admin"
      can :manage, :all
      can :access, :admin
    when "user"
      # User
    end
  end
end
