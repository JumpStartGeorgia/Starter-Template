require 'rails_helper'

RSpec.describe 'Users', type: :request do
  before(:example) do
    @role = FactoryGirl.create(:role, name: 'site_admin')
    @user = FactoryGirl.create(:user, role: @role)
    login_as(@user, scope: :user)
  end

  describe 'GET /users' do
    it 'works' do
      get users_path
      expect(response).to have_http_status(200)
    end
  end
end
