module RedmineCrmMailchimp
  module Patches
    module ContactsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :contact_tabs, :mailchimp
        end
      end


      module InstanceMethods

        def contact_tabs_with_mailchimp(contact)
          tabs = contact_tabs_without_mailchimp(contact)

          if contact.email.present? &&
            Setting.plugin_redmine_crm_mailchimp[:api_key].present? &&
            User.current.allowed_to?(:view_mailchimp, @project)
            tabs.push({:name => 'mailchimp', :partial => 'mailchimp/contact_tab', :label => l(:label_mailchimp)})
          end
          tabs
        end

      end

    end
  end
end

unless ContactsHelper.included_modules.include?(RedmineCrmMailchimp::Patches::ContactsHelperPatch)
  ContactsHelper.send(:include, RedmineCrmMailchimp::Patches::ContactsHelperPatch)
end
