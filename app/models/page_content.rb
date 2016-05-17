class PageContent < ActiveRecord::Base
  translates :title, :content, :fallbacks_for_empty_translations => true

  validates :name, presence: :true, uniqueness: :true

  # Allows reference of specific translations, i.e. post.title_az
  # or post.title_en
  globalize_accessors
end
