require 'rails_helper'

RSpec.describe User, type: :model do
  let(:new_user) { FactoryGirl.build(:user) }

  context 'with required attributes' do
    it 'is valid' do
      pending
    end
  end

  describe 'email' do
    context 'when present' do
      it 'does not cause error' do
        expect(new_user).to have(0).error_on(:email)
      end
    end

    context 'when blank' do
      before :example do
        new_user.email = ''
      end

      it 'causes error' do
        expect(new_user).to have(1).error_on(:email)
      end
    end
  end

  describe 'role' do
    context 'when present' do
      it 'does not cause error' do
        expect(new_user).to have(0).error_on(:role)
      end
    end

    context 'when blank' do
      before :example do
        new_user.role = nil
      end

      it 'causes error' do
        expect(new_user).to have(1).error_on(:role)
      end
    end
  end
end
