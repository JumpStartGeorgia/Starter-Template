Rails.application.config.middleware
  .use ExceptionNotification::Rack,
       email: {
         email_prefix: "[Bootstrap Starter App Error (#{Rails.env})] ",
         sender_address: [ENV['APPLICATION_ERROR_FROM_EMAIL']],
         exception_recipients: [ENV['APPLICATION_FEEDBACK_TO_EMAIL']]
       }
