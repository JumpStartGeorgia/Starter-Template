require 'capybara/rspec'
require 'capybara-screenshot/rspec'

RSpec.configure do |config|
  # Only keeps html and png screenshots from the last test run
  Capybara::Screenshot.prune_strategy = :keep_last_run

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.current_driver = :selenium_chrome
end
