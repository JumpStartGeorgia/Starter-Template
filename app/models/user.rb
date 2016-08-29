# Contains account data
class User < ApplicationRecord
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

  # requested_role may be the name of one role (a string)
  # or an array of possible roles
  def is?(requested_role)
    self.role_id && ((requested_role.is_a?(String) && role.name == requested_role) || (requested_role.is_a?(Array) && requested_role.include?(self.role.name)))
  end

  def manageable_roles
    Role.all.select { |role| Ability.new(self).can? :manage, role }
  end
end
