RSpec.configure do |config|
  def t(string, options = {})
    I18n.t(string, options)
  end

  def l(string, options = {})
    I18n.l(string, options)
  end

  # Adds locale to params in controller tests
  # Originally taken from http://stackoverflow.com/a/19079076/3115911,
  # then modified to work with Rails 5.
  module ActionController
    class TestCase
      module Behavior
        module LocaleParameter
          # rubocop:disable MethodLength
          def process(action, parameters = {params: {}})

            unless I18n.locale.nil?
              parameters[:params][:locale] = I18n.locale
            end

            super(action, parameters)
          end
          # rubocop:enable MethodLength
        end

        prepend Behavior::LocaleParameter
      end
    end
  end

  # Makes routing specs work with default locale
  module ActionDispatch
    module Routing
      # Top-level doc comment for rubocop
      class RouteSet
        def default_url_options(_options = {})
          { locale: I18n.default_locale }
        end
      end
    end
  end

  config.before(:each, type: :feature) do
    default_url_options[:locale] = I18n.default_locale
  end

  # COMMENTED OUT BELOW CODE BECAUSE IT'S COPIED FROM PRISONERS.WATCH PROJECT
  # AND MAY BE UNNEEDED
  #
  # config.before(:each, type: :request) do
  #   default_url_options[:locale] = I18n.default_locale
  # end
end
