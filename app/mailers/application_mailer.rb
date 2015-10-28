# Mailer defaults for whole app
class ApplicationMailer < ActionMailer::Base
  default from: ENV['APPLICATION_FEEDBACK_FROM_EMAIL']
end
