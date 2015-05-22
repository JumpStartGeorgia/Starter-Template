module ApplicationHelper
  def page_title(page_title)
    content_for(:page_title) { page_title.html_safe }
  end

  def page_subtitle(page_subtitle)
    content_for(:page_subtitle) { page_subtitle.html_safe }
  end
end
