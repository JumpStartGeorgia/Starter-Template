# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).

# To run seeds
# bundle exec rake db:seed create_user_accounts=true

puts 'BEGIN SEEDING DATABASE'

roles = %w(super_admin site_admin content_manager)
roles.each do |role|
  Role.find_or_create_by(name: role)
end

# if this is not production
# and variable is set, create users if not exist
if ENV['create_user_accounts'].present? && !Rails.env.production?
  test_user_password = 'password123'

  test_users = [
    {
      email: 'super.admin@test.ge',
      password: test_user_password,
      role: 'super_admin'
    },
    {
      email: 'site.admin@test.ge',
      password: test_user_password,
      role: 'site_admin'
    },
    {
      email: 'content.manager@test.ge',
      password: test_user_password,
      role: 'content_manager'
    }
  ]

  test_users.each do |test_user_data|
    old_test_user = User.find_by_email(test_user_data[:email])
    old_test_user.destroy if old_test_user.present?

    puts "\nCREATING USER (#{test_user_data[:role]})\nEmail: #{test_user_data[:email]}\nPassword: #{test_user_data[:password]}\n"

    User.create(
      email: test_user_data[:email],
      password: test_user_data[:password],
      role: Role.find_by_name(test_user_data[:role])
    )
  end
end

puts "\nEND SEEDING DATABASE"
