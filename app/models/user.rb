# Contains account data
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  belongs_to :role
  # Email already required by devise
  validates :role, presence: true

  def is?(requested_role)
    if role
      role.name == requested_role
    else
      return false
    end
  end

  def manageable_roles
    roles = []
    Role.all.each do |role|
      roles.append(role) if can_create? role
    end

    roles
  end

  def can_manage?(role)
    Ability.new(self).can? :manage,
                           User.new(
                             email: 'assdfasdfasdf@asdfdsffsd.com',
                             password: '1234231432143',
                             role: role
                           )
  end
end
