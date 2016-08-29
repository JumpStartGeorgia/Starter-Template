class AddMissingTranslation < ApplicationRecord
  self.abstract_class = true

  #######################
  ## CALLBACKS

  before_save :set_missing_translations

  #######################
  #######################
  private

  # if there are any required translation fields that are missing values, add them
  def set_missing_translations
    default_trans = nil
    default_locale = nil
    # check if default locale is ok
    Globalize.with_locale(I18n.default_locale) do
      if has_required_translations?(self)
        default_trans = self.clone
        default_locale = I18n.default_locale
      end
    end

    # if the default locale is not ok, look at other locales
    if default_trans.nil?
      locales = I18n.available_locales.clone
      locales.delete(I18n.default_locale)

      locales.each do |locale|
        Globalize.with_locale(locale) do
          if has_required_translations?(self)
            default_trans = self.clone
            default_locale = locale
          end
        end
        break if default_trans.present?
      end
    end

    # if found a good trans, go through the other locales and add missing data
    if default_trans.present? && default_locale.present?
      locales = I18n.available_locales.clone
      locales.delete(default_locale)

      locales.each do |locale|
        Globalize.with_locale(locale) do
          add_missing_translations(default_trans)
        end
      end
    end

  end

  # this method needs to be overriden
  def has_required_translations?(trans)
  end

  # this method needs to be overriden
  def add_missing_translations(default_trans)
  end

end
