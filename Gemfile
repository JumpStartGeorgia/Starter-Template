source 'https://rubygems.org'

#####################################################################
##################### Starter Template Gems #########################

# The framework! :)
gem 'rails', '~> 5.0.0'

# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18.4'

# SCSS parsing in asset pipeline
gem 'sass-rails', '~> 5.0.6'

# CSS and JS compression for production
gem 'uglifier', '~> 3.0.2'

# Makes jQuery available in rails JS
gem 'jquery-rails', '~> 4.2.1'

# Uses caching to improve performance for internal page changes
gem 'turbolinks', '~> 5.0.1'

# JSON creation
gem 'jbuilder', '~> 2.6.0'

# Stores project secrets in environment variables
gem 'dotenv-rails', '~> 2.1.1'

# Makes compatibility easier for jQuery and turbolinks
gem 'jquery-turbolinks', '~> 2.1.0'

# Makes jQuery UI (like jQuery datepicker) available
gem 'jquery-ui-rails', '~> 5.0.5'

# Simplifies form creation
gem 'formtastic', '~> 3.1.4'

# JavaScript interpreter
gem 'therubyracer', '~> 0.12.1'

# Bootstrap JS and various bootstrap-related generators/helpers
gem 'twitter-bootstrap-rails', '~> 3.2.0'

# Use formtastic to generate bootstrap-styled forms
gem 'formtastic-bootstrap', '~> 3.1.0'

# Authentication
gem 'devise', '~> 4.2.0'

# Authorization
gem 'cancancan', '~> 1.15.0'

# So that our SCSS can use bootstrap variables
gem 'bootstrap-sass', '~> 3.3.5'

# Useful icons
gem 'font-awesome-sass', '~> 4.4.0'

# Ruby server
gem 'puma', '~> 3.6'

# sends updates to google analytics when turbolinks changes page
gem 'google-analytics-turbolinks', '~> 0.0.4'

# Sends email when exception or error is thrown
gem 'exception_notification', '~> 4.1', '>= 4.1.4'


# translate models
gem 'activemodel-serializers-xml', '~> 1.0.1'
gem 'globalize', github: 'globalize/globalize'
gem 'globalize-accessors', '~> 0.2.1'

# send variables to javascript
gem 'gon', '~> 6.0', '>= 6.0.1'

# required to load assets
gem 'coffee-script', '~> 2.4', '>= 2.4.1'

group :development do
  # Recommends SQL query performance optimizations
  gem 'bullet', '~> 5.3'

  # Static code analyzer that finds potential security issues
  gem 'brakeman', '~> 3.2.1', require: false

  # Finds unused and missing translations
  gem 'i18n-tasks', '~> 0.9.5'

  # Server-related tasks (such as deploy)
  gem 'mina', '~> 0.3.8', require: false

  # Mina for multiple servers
  gem 'mina-multistage', '~> 1.0.2', require: false

  # Prints arrays, hashes, etc. beautifully
  gem 'awesome_print', '~> 1.6', '>= 1.6.1'

  # Export and import locale files to work with translators
  gem 'locales_export_import', '~> 0.4.2'

  # show model attributes (table fields) in model
  gem 'annotate', '~> 2.7'

  # Adds a console to application errors in browser
  gem 'web-console', '~> 2.0'

  # Useful performance profiling gems. Load a page with url param ?pp=help
  # for more info.
  gem 'flamegraph', '~> 0.9.5'
  gem 'rack-mini-profiler', '~> 0.10.1'
  gem 'stackprof', '~> 0.2.9'
end

group :test do
  # Specification testing
  gem 'rspec-rails', '~> 3.5.2'

  # Adds syntax to check that a collection has a certain number of something
  # Ex: expect(new_user).to have(1).error_on(:role)
  gem 'rspec-collection_matchers', '~> 1.1.2'

  # Brings back 'assigns' and 'assert_template' to controller specs in rails 5
  gem 'rails-controller-testing', '~> 1.0.1'

  # Easy data creation in tests
  gem 'factory_girl_rails', '~> 4.5.0'

  # Testing API for Rack apps
  gem 'rack-test', '~> 0.6.3'

  # Feature testing
  gem 'capybara', '~> 2.8.1'

  # Can launch browser in case of feature spec errors
  gem 'launchy', '~> 2.4.3'

  # Web driver for feature tests
  gem 'selenium-webdriver', '~> 2.44.0'

  # Tasks screenshots when capybara feature test fails
  gem 'capybara-screenshot', '~> 1.0.4'

  # Cleans database during tests
  gem 'database_cleaner', '~> 1.3.0'

  # Fast web driver with JavaScript support for feature tests
  gem 'poltergeist', '~> 1.7'

  # Feature testing for emails
  gem 'capybara-email', '~> 2.4'
end

group :development, :test do
  # Debugging: write 'binding.pry' in Ruby code to debug in terminal
  gem 'pry-byebug', '~> 3.1.0'

  # Rails app preloader; runs app in background to speed up dev environment
  gem 'spring', '~> 1.3.5'

  # Ruby code style
  gem 'rubocop', '~> 0.35.0'
end

#####################################################################
########################## Project Gems #############################
