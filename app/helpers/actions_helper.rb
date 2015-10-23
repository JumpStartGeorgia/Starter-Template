# Action button helpers, i.e. to easily create a 'Show User' button
module ActionsHelper
  def view_button(object)
    link_to t('shared.actions.with_obj.view_page',
              obj: t("activerecord.models.#{object.model_name.singular}",
                     count: 1)),
            object,
            class: 'btn btn-default'
  end

  def view_all_button(object)
    link_to t('shared.actions.with_obj.view_all',
              obj: t("activerecord.models.#{object.model_name.singular}",
                     count: 999)),
            url_for(object),
            class: 'btn btn-default'
  end

  def new_button(model_class, new_path)
    link_to t('shared.actions.with_obj.new',
              obj: t("activerecord.models.#{model_class.model_name.singular}",
                     count: 1)),
            new_path,
            class: 'btn btn-primary'
  end
end
