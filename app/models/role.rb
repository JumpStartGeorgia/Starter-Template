# Allows authorization of certain actions based on user role
class Role < ApplicationRecord
  has_many :users
end
