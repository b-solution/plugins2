module RedmineHelpdesk
  module Hooks
    class HelperIssuesHook < Redmine::Hook::ViewListener

      def helper_issues_show_detail_after_setting(context={})
        if context[:detail].prop_key == 'vote'
          detail = context[:detail]
          context[:detail].value = HelpdeskTicket.vote_message(detail.value) if detail.value && detail.value.to_s =~ /^\d$/
          context[:detail].old_value = HelpdeskTicket.vote_message(detail.old_value) if detail.old_value && detail.old_value.to_s =~ /^\d$/
        end
      end

    end
  end
end