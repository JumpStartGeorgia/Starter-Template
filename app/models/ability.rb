# Defines abilities of roles
#
# Documentation:
# https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    content_resources = []
    if user.is? 'super_admin'
      can :manage, :all
    elsif user.is? 'site_admin'
      can :manage, content_resources
      can [:read, :new], User
      can [:edit, :create, :update, :destroy], User, role: { name: 'site_admin' }
      can [:edit, :create, :update, :destroy], User, role: { name: 'content_manager' }
    elsif user.is? 'content_manager'
      can :manage, content_resources
    end

    # Actions everyone can do:
    can :read, content_resources
  end
end
