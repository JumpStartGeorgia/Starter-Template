require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: users_path).to route_to('users#index', locale: 'en')
    end

    it 'routes to #new' do
      expect(get: new_user_path).to route_to('users#new', locale: 'en')
    end

    it 'routes to #show' do
      expect(get: user_path(:en, 1)).to route_to('users#show', id: '1', locale: 'en')
    end

    it 'routes to #edit' do
      expect(get: edit_user_path(:en, 1)).to route_to('users#edit', id: '1', locale: 'en')
    end

    it 'routes to #create' do
      expect(post: users_path).to route_to('users#create', locale: 'en')
    end

    it 'routes to #update' do
      expect(put: user_path(:en, 1)).to route_to('users#update', id: '1', locale: 'en')
    end

    it 'routes to #destroy' do
      expect(delete: user_path(:en, 1)).to route_to('users#destroy', id: '1', locale: 'en')
    end
  end
end
