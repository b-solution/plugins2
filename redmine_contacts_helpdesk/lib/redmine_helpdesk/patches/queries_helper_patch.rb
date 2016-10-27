require_dependency 'queries_helper'

module RedmineHelpdesk
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :column_content, :helpdesk
        end
      end


      module InstanceMethods
        include ContactsHelper


        def column_content_with_helpdesk(column, issue)
          if column.name.eql?(:last_message) && issue.helpdesk_ticket && issue.is_a?(Issue)
              content_tag(:span, '', :class => "icon #{issue.helpdesk_ticket.last_message.is_incoming ? 'icon-email' : 'icon-email-to'}") +
              link_to(content_tag(:span, content_tag(:small, issue.helpdesk_ticket.last_message.content.truncate(250)), :class => 'description'),
                      {:controller => 'issues', :action => 'show', :id => issue.id, :anchor => "change-#{issue.helpdesk_ticket.last_message.id}"})
          elsif column.name.eql?(:customer) && issue.is_a?(Issue)
            issue.customer ? contact_tag(issue.customer, :type => "plain") : ""
          elsif column.name.eql?(:customer_company) && issue.is_a?(Issue)
            issue.customer ? issue.customer.company : ""
          elsif column.name.eql?(:ticket_source) && issue.is_a?(Issue)
            issue.helpdesk_ticket ? issue.helpdesk_ticket.ticket_source_name : ""
          elsif column.name.eql?(:ticket_reaction_time) && issue.is_a?(Issue)
            issue.ticket_reaction_time
          elsif column.name.eql?(:ticket_first_response_time) && issue.is_a?(Issue)
            issue.ticket_first_response_time
          elsif column.name.eql?(:ticket_resolve_time) && issue.is_a?(Issue)
            issue.ticket_resolve_time
          elsif column.name.eql?(:last_message_date) && issue.is_a?(Issue)
            issue.helpdesk_ticket ? l(:label_helpdesk_ago, time_tag(issue.helpdesk_ticket.last_message_date)) : ""
          elsif column.name.eql?(:helpdesk_ticket) && issue.customer && issue.is_a?(Issue)
            contact_tag(issue.customer, :size => "32", :type => "avatar", :class => "avatar") +
            content_tag(:div,
              content_tag(:p, link_to(issue.subject, issue_path(issue)), :class => 'ticket-name') +
              content_tag(:p, content_tag(:small, issue.description.gsub("(\n|\r)", "").strip.truncate(100)), :class => "ticket-description") +
              content_tag(:p, "#{content_tag('span', '', :class => "icon #{helpdesk_ticket_source_icon(issue.helpdesk_ticket)}", :title => l(:label_note_type_email))} #{l(:label_helpdesk_from)}: #{contact_tag(issue.customer, :type => "plain")}, ".html_safe + l(:label_updated_time, time_tag(issue.helpdesk_ticket.last_message_date)).html_safe, :class => "contact-info"),
            :class => 'ticket-data')
            # content_tag(:div, content_tag(:span, issue.status.name, :class => "tag-label-color status-#{issue.status.id}" , :style => "background-color: #{tag_color(issue.status.name)}"), :class => "ticket-status")
          elsif column.name.eql?(:vote) && issue.helpdesk_ticket && issue.is_a?(Issue)
            content_tag(:span, HelpdeskTicket.vote_message(issue.helpdesk_ticket.vote)) if issue.helpdesk_ticket.vote
          elsif column.name.eql?(:vote_comment) && issue.helpdesk_ticket && issue.is_a?(Issue)
            textilizable(issue.helpdesk_ticket.vote_comment.to_s)
          else
            column_content_without_helpdesk(column, issue)
          end
        end

      end
    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineHelpdesk::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineHelpdesk::Patches::QueriesHelperPatch)
end
