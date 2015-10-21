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
  validates :email, :role, presence: true

  def is?(requested_role)
    if role
      role.name == requested_role
    else
      return false
    end
  end
end
