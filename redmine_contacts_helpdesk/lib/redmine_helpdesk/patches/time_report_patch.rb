module RedmineHelpdesk
  module Patches
    module TimeReportPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :load_available_criteria, :helpdesk
        end
      end


      module InstanceMethods
        def load_available_criteria_with_helpdesk
          @available_criteria = load_available_criteria_without_helpdesk
          @available_criteria['customer'] = {:sql => "c_helpdesk_tickets.contact_id",
                                                 :kclass => Contact,
                                         :joins => "LEFT OUTER JOIN helpdesk_tickets c_helpdesk_tickets ON c_helpdesk_tickets.issue_id = issues.id",
                                         :label => :label_helpdesk_customer} if User.current.allowed_to?(:view_helpdesk_tickets, @project, :global => true)
          @available_criteria['helpdesk_contact_company'] = {
                                             :sql => "hcc_contacts.company",
                                             :kclass => Contact,
                                             :joins => "LEFT OUTER JOIN helpdesk_tickets hcc_helpdesk_tickets ON hcc_helpdesk_tickets.issue_id = issues.id LEFT OUTER JOIN contacts hcc_contacts on hcc_helpdesk_tickets.contact_id = hcc_contacts.id",
                                             :label => :label_helpdesk_customer_company} if User.current.allowed_to?(:view_helpdesk_tickets, @project, :global => true)

          @available_criteria
        end

      end

    end
  end
end

unless Redmine::Helpers::TimeReport.included_modules.include?(RedmineHelpdesk::Patches::TimeReportPatch)
  Redmine::Helpers::TimeReport.send(:include, RedmineHelpdesk::Patches::TimeReportPatch)
end