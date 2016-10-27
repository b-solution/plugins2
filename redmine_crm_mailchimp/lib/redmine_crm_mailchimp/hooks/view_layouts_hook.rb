module RedmineCrmMailchimp
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        stylesheet_link_tag(:redmine_crm_mailchimp, :plugin => 'redmine_crm_mailchimp') +
            javascript_include_tag(:redmine_crm_mailchimp, :plugin => 'redmine_crm_mailchimp')
      end
    end
  end
end