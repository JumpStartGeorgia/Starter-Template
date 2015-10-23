# Action button helpers, i.e. to easily create a 'Show User' button
module ActionsHelper
  def show_button
  end

  def view_all_button(object)
    link_to t('shared.actions.with_obj.view_all',
              obj: t("activerecord.models.#{object.model_name.singular}", count: 999)),
            url_for(object),
            class: 'btn btn-default'
  end
end
