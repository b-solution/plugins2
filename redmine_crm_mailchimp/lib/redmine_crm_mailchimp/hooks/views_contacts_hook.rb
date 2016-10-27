module RedmineCrmMailchimp
  module Hooks
    class ViewsContextMenuesHook < Redmine::Hook::ViewListener
      render_on :view_contacts_context_menu_before_delete, :partial => "mailchimp/contacts_context_menu"
    end
  end
end
