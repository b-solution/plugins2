module RedmineHelpdesk
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          # before_filter :apply_helpdesk_macro, :only => :update
          after_filter :flash_helpdesk, :only => :update
          after_filter :send_auto_answer, :only => :create

          alias_method_chain :build_new_issue_from_params, :helpdesk
          alias_method_chain :update_issue_from_params, :helpdesk
          helper :helpdesk
        end
      end

      module InstanceMethods

        def flash_helpdesk
          if @issue.current_journal.is_send_note
            render_send_note_warning_if_needed(@issue.current_journal)
            flash[:notice] = flash[:notice].to_s + " " + l(:notice_email_sent, "<span class='icon icon-email'>" + @issue.current_journal.journal_message.to_address  + "</span>") if @issue.current_journal.send_note_errors.blank?
          end
        end

        def send_auto_answer
          return unless @issue && @issue.customer && User.current.allowed_to?(:send_response, @project)
          case params[:helpdesk_send_as].to_i
            when HelpdeskTicket::SEND_AS_NOTIFICATION
              msg = HelpdeskMailer.auto_answer(@issue.customer, @issue).deliver
            when HelpdeskTicket::SEND_AS_MESSAGE
              if msg = HelpdeskMailer.initial_message(@issue.customer, @issue, params).deliver
                @issue.helpdesk_ticket.message_id = msg.message_id
                @issue.helpdesk_ticket.is_incoming = false
                @issue.helpdesk_ticket.from_address = @issue.customer.primary_email
                @issue.helpdesk_ticket.save
              end
          end
          flash[:notice].blank? ? flash[:notice] = l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first  + "</span>") : flash[:notice] << " " + l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first  + "</span>") if msg
        rescue Exception => e
            flash[:error].blank? ? flash[:error] = e.message : flash[:error] << " " + e.message
        end

        def update_issue_from_params_with_helpdesk
          is_updated = update_issue_from_params_without_helpdesk
          return false unless is_updated
          if params[:helpdesk] && params[:helpdesk][:is_send_mail] && User.current.allowed_to?(:send_response, @project) && @issue.customer
            @issue.current_journal.build_journal_message
            @issue.current_journal.journal_message.update_attributes(params[:journal_message])
            @issue.current_journal.journal_message.to_address ||= @issue.customer.primary_email
            @issue.current_journal.is_send_note = true
            @issue.current_journal.notes = HelpdeskMailer.apply_macro(@issue.current_journal.notes, @issue.customer, @issue, User.current)
          end
          is_updated
        end

        def build_new_issue_from_params_with_helpdesk
          build_new_issue_from_params_without_helpdesk
          return if @issue.blank? || params[:customer_id].blank?
          contact = Contact.visible.find_by_id(params[:customer_id])
          @issue.build_helpdesk_ticket(:issue => @issue, :ticket_date => Time.now, :customer => contact) if contact
          @issue.helpdesk_ticket.source = params[:source] if params[:source]
        end

        def render_send_note_warning_if_needed(journal)
          return false if journal.blank? || journal.journal_message.blank?
          flash[:warning] = flash[:warning].to_s + " " + l(:label_helpdesk_email_sending_problems) + ": " + journal.send_note_errors unless journal.send_note_errors.blank?
        end

      end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineHelpdesk::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineHelpdesk::Patches::IssuesControllerPatch)
end
