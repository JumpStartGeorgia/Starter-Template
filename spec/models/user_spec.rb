require 'rails_helper'

RSpec.describe User, type: :model do
  let(:new_user) { FactoryGirl.build(:user) }

  it 'is valid with valid attributes' do
    expect(new_user).to be_valid
  end

  describe 'email' do
    it 'is required' do
      new_user.email = ''
      expect(new_user).to have(1).error_on(:email)
    end
  end

  describe 'role' do
    it 'is required' do
      new_user.role = nil
      expect(new_user).to have(1).error_on(:role)
    end
  end
end
