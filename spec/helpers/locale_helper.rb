RSpec.configure do |_config|
  def t(string, options = {})
    I18n.t(string, options)
  end

  def l(string, options = {})
    I18n.l(string, options)
  end

  #### TODO COMMENTED OUT BELOW CODE BECAUSE IT'S COPIED FROM PRISONERS PROJECT AND NOT SURE IF IT'S NEEDED

  # # Makes controllers work with default locale
  # # Taken from http://stackoverflow.com/a/19079076/3115911
  # class ActionController::TestCase
  #   module Behavior
  #     def process_with_default_locale(action, http_method = 'GET', parameters = nil, session = nil, flash = nil)
  #       parameters = { locale: I18n.locale }.merge(parameters || {}) unless I18n.locale.nil?
  #       process_without_default_locale(action, http_method, parameters, session, flash)
  #     end
  #     alias_method_chain :process, :default_locale
  #   end
  # end
  #
  # config.before(:each, type: :feature) do
  #   default_url_options[:locale] = I18n.default_locale
  # end
  #
  # config.before(:each, type: :request) do
  #   default_url_options[:locale] = I18n.default_locale
  # end
  #
  # # Makes routing specs work with default locale
  # class ActionDispatch::Routing::RouteSet
  #   def default_url_options(_options = {})
  #     { locale: I18n.default_locale }
  #   end
  # end
end
