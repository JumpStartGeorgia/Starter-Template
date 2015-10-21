require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { FactoryGirl.build(:user) }

  context 'with required attributes' do
    it 'is valid' do
      pending
    end
  end

  describe 'email' do
    context 'when present' do
      it 'does not cause error' do
        pending
      end
    end

    context 'when blank' do
      it 'causes error' do
        pending
      end
    end
  end

  describe 'role' do
    context 'when present' do
      it 'does not cause error' do
        pending
      end
    end

    context 'when blank' do
      it 'causes error' do
        pending
      end
    end
  end
end
