Redmine::Plugin.register :redmine_crm_mailchimp do
  name 'RedmineCRM Mailchimp plugin'
  author 'RedmineCRM'
  description 'This is a plugin for RedmineCRM to integrate MailChimp mailing sevice with contacts'
  version '1.0.1'
  url 'http://redminecrm.com/pages/extensions_mailchimp'
  author_url 'mailto:support@redminecrm.com'

  begin
    requires_redmine_plugin :redmine_contacts, :version_or_higher => '3.3.0'
  rescue Redmine::PluginNotFound  => e
    raise "Please install redmine_contacts plugin"
  end

  menu :admin_menu, :mailchimp_settings, {:controller => 'settings', :action => 'plugin', :id => :redmine_crm_mailchimp}, :caption => :label_mailchimp_settings

  settings :default => {
    :api_key => ''
  }, :partial => 'settings/mailchimp/mailchimp'
  project_module :mailchimp do
    permission :view_mailchimp, { :mailchimp_memberships => :show, :mailchimp => [:lists, :campaigns] }
    permission :edit_mailchimp, { :mailchimp_memberships => [ :edit, :destroy, :create, :bulk_update, :bulk_edit, :test_api ], :mailchimp => [:lists, :campaigns] }
  end
end

require 'redmine_crm_mailchimp'
