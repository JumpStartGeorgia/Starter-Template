require 'capybara/rspec'
require 'capybara-screenshot/rspec'

RSpec.configure do |_config|
  # Only keeps html and png screenshots from the last test run
  Capybara::Screenshot.prune_strategy = :keep_last_run

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.current_driver = :selenium_chrome

  #### TODO COMMENTED OUT BELOW CODE BECAUSE IT'S COPIED FROM PRISONERS PROJECT AND NOT SURE IF IT'S NEEDED

  # # Helper function for Capybara to select options in multiple jQuery select2
  # def select2_select_multiple(select_these, select_id)
  #   # This methods requires @javascript in the Scenario
  #   [select_these].flatten.each do |value|
  #     clickable_input = find(:xpath, "//*[contains(@id, '#{select_id}')]//input[contains(@class, 'select2-input')]")
  #     clickable_input.click
  #     found = false
  #     within('.select2-drop') do
  #       all('li.select2-result').each do |result|
  #         unless found
  #           if result.text == value
  #             result.click
  #             found = true
  #           end
  #         end
  #       end
  #     end
  #   end
  # end
end
