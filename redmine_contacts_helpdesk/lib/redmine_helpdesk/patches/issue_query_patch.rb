require_dependency 'query'

module RedmineHelpdesk
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, HelpdeskHelper)

        base.class_eval do
          unloadable

          alias_method_chain :available_columns, :helpdesk
          alias_method_chain :available_filters, :helpdesk
          alias_method_chain :joins_for_order_statement, :helpdesk
          alias_method_chain :issues, :helpdesk

        end
      end


      module InstanceMethods
        # def issues_with_helpdesk(options={})
        #   if project.blank? || (project && User.current.allowed_to?(:view_helpdesk_tickets, project))
        #     options[:include] = (options[:include] || []) + [:helpdesk_ticket]
        #   end
        #   issues_without_helpdesk(options)
        # end

        def issues_with_helpdesk(options={})
          issues = issues_without_helpdesk(options)
          if has_column?(:last_message) || has_column?(:last_message_date) || has_column?(:customer) || has_column?(:ticket_source) || has_column?(:customer_company) || has_column?(:helpdesk_ticket) || has_column?(:ticket_reaction_time) || has_column?(:ticket_first_response_time) || has_column?(:ticket_resolve_time) || has_column?(:vote) || has_column?(:vote_comment)
            Issue.load_helpdesk_data(issues)
          end
          issues
        end

        def joins_for_order_statement_with_helpdesk(order_options)
          joins = joins_for_order_statement_without_helpdesk(order_options)
          ticket_joins = [joins].flatten
          if order_options && (order_options.include?('reaction_time') ||
                               order_options.include?('first_response_time') ||
                               order_options.include?('resolve_time') ||
                               order_options.include?('vote'))
            ticket_joins << "LEFT OUTER JOIN #{HelpdeskTicket.table_name} ON #{Issue.table_name}.id = #{HelpdeskTicket.table_name}.issue_id"
          end
          ticket_joins.any? ? ticket_joins.join(' ') : nil
        end


        def sql_for_customer_field(field, operator, value)
          case operator
          when "*", "!*" # Member / Not member
            sw = operator == "!*" ? 'NOT' : ''
            "(#{Issue.table_name}.id #{sw} IN (SELECT DISTINCT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}))"
          when "=", "!"
            sw = operator == "!" ? 'NOT' : ''
            contacts_select = "SELECT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}
                                WHERE #{HelpdeskTicket.table_name}.contact_id IN (#{value.join(',')})"

            "(#{Issue.table_name}.id #{sw} IN (#{contacts_select}))"
          end
        end

        def sql_for_ticket_source_field(field, operator, value)
          case operator
          when "=", "!"
            sw = operator == "!" ? 'NOT' : ''
            contacts_select = "SELECT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}
                                WHERE #{HelpdeskTicket.table_name}.source IN (#{value.join(',')})"

            "(#{Issue.table_name}.id #{sw} IN (#{contacts_select}))"
          end
        end

        def sql_for_customer_company_field(field, operator, value)
          sw = ["!", "!~"].include?(operator) ? 'NOT' : ''
          case operator
          when "="
            like_value = "LIKE '#{value.first.to_s}'"
          when "!*"
            like_value = "IS NULL OR #{Contact.table_name}.company = ''"
          when "*"
            like_value = "IS NOT NULL OR #{Contact.table_name}.company <> ''"
          when "~", "!~"
            like_value ="LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
          end

          contacts_select = "SELECT #{HelpdeskTicket.table_name}.issue_id FROM #{HelpdeskTicket.table_name}
                              WHERE #{HelpdeskTicket.table_name}.contact_id IN (
                                SELECT #{Contact.table_name}.id
                                FROM #{Contact.table_name}
                                WHERE LOWER(#{Contact.table_name}.company) #{like_value}
                                )"

          "(#{Issue.table_name}.id #{sw} IN (#{contacts_select}))"
        end

        def sql_for_ticket_reaction_time_field(field, operator, value)
          "(#{Issue.table_name}.id IN (SELECT #{HelpdeskTicket.table_name}.issue_id
              FROM #{HelpdeskTicket.table_name}
              WHERE #{sql_for_field(field, operator, value.map{|v| v.to_i * 60},
                        HelpdeskTicket.table_name, "reaction_time")}))"
        end

        def sql_for_ticket_first_response_time_field(field, operator, value)
          "(#{Issue.table_name}.id IN (SELECT #{HelpdeskTicket.table_name}.issue_id
              FROM #{HelpdeskTicket.table_name}
              WHERE #{sql_for_field(field, operator, value.map{|v| v.to_i * 60},
                        HelpdeskTicket.table_name, "first_response_time")}))"
        end

        def sql_for_ticket_resolve_time_field(field, operator, value)
          "(#{Issue.table_name}.id IN (SELECT #{HelpdeskTicket.table_name}.issue_id
              FROM #{HelpdeskTicket.table_name}
              WHERE #{sql_for_field(field, operator, value.map{|v| v.to_i * 60},
                        HelpdeskTicket.table_name, "resolve_time")}))"
        end

        def sql_for_vote_field(field, operator, value)
          case operator
            when '=', '*'
              compare = 'IN'
            when '!', '!*'
              compare = 'NOT IN'
          end
          issues_select = "SELECT DISTINCT(issue_id) FROM helpdesk_tickets WHERE vote IN (#{ value.join(',') })"
          issues_with_votes = 'SELECT DISTINCT(issue_id) FROM helpdesk_tickets WHERE vote IS NOT NULL'
          "(#{Issue.table_name}.id #{compare} (#{ %w(= !).include?(operator) ? issues_select : issues_with_votes }))"
        end

        def available_columns_with_helpdesk
          if @available_columns.blank? && User.current.allowed_to?(:view_helpdesk_tickets, project, :global => true)
            @available_columns = available_columns_without_helpdesk
            @available_columns << QueryColumn.new(:last_message, :caption => :label_helpdesk_last_message)
            @available_columns << QueryColumn.new(:last_message_date, :caption => :label_helpdesk_last_message_date)
            @available_columns << QueryColumn.new(:customer, :caption => :label_helpdesk_customer)
            @available_columns << QueryColumn.new(:ticket_source, :caption => :label_helpdesk_ticket_source)
            @available_columns << QueryColumn.new(:customer_company, :caption => :label_helpdesk_customer_company)
            @available_columns << QueryColumn.new(:helpdesk_ticket, :caption => :label_helpdesk_ticket)
            @available_columns << QueryColumn.new(:ticket_reaction_time, :caption => :label_helpdesk_ticket_reaction_time, :sortable => "#{HelpdeskTicket.table_name}.reaction_time")
            @available_columns << QueryColumn.new(:ticket_first_response_time, :caption => :label_helpdesk_ticket_first_response_time, :sortable => "#{HelpdeskTicket.table_name}.first_response_time")
            @available_columns << QueryColumn.new(:ticket_resolve_time, :caption => :label_helpdesk_ticket_resolve_time, :sortable => "#{HelpdeskTicket.table_name}.resolve_time")
            @available_columns << QueryColumn.new(:vote, :caption => :label_helpdesk_vote, :sortable => "#{HelpdeskTicket.table_name}.vote")
            @available_columns << QueryColumn.new(:vote_comment, :caption => :label_helpdesk_vote_comment)
          else
            available_columns_without_helpdesk
          end
          @available_columns
        end

        def available_filters_with_helpdesk
          # && !RedmineHelpdesk.settings[:issues_filters]
          if @available_filters.blank? && User.current.allowed_to?(:view_helpdesk_tickets, project, :global => true)
            available_filters_without_helpdesk.merge!({ 'customer' => {
                :type => :list_optional,
                :name => l(:label_helpdesk_customer),
                :order  => 6,
                :values => contacts_for_select(project, :limit => 500) }}) unless available_filters_without_helpdesk.key?("customer")

            available_filters_without_helpdesk.merge!({ 'ticket_source' => {
                :type => :list,
                :name => l(:label_helpdesk_ticket_source),
                :order  => 7,
                :values => helpdesk_tickets_source_for_select }}) unless available_filters_without_helpdesk.key?("ticket_source")

            available_filters_without_helpdesk.merge!({ 'customer_company' => {
                :type => :string,
                :name => l(:label_helpdesk_customer_company),
                :order  => 8 }}) unless available_filters_without_helpdesk.key?("customer_company")

            available_filters_without_helpdesk.merge!({ 'ticket_reaction_time' => {
                :type => :integer,
                :name => l(:label_helpdesk_ticket_reaction_time)}
            }) unless available_filters_without_helpdesk.key?("ticket_reaction_time")

            available_filters_without_helpdesk.merge!({ 'ticket_first_response_time' => {
                :type => :integer,
                :name => l(:label_helpdesk_ticket_first_response_time)}
            }) unless available_filters_without_helpdesk.key?("ticket_first_response_time")

            available_filters_without_helpdesk.merge!({ 'ticket_resolve_time' => {
                :type => :integer,
                :name => l(:label_helpdesk_ticket_resolve_time)}
            }) unless available_filters_without_helpdesk.key?("ticket_resolve_time")

            available_filters_without_helpdesk.merge!({ 'vote' => {
              :type   => :list_optional,
              :name => l(:label_helpdesk_vote),
              :values => [[l(:label_helpdesk_mark_awesome), "2"], [l(:label_helpdesk_mark_justok), "1"], [l(:label_helpdesk_mark_notgood), "0"]]
            }}) unless available_filters_without_helpdesk.key?("vote")

          else
            available_filters_without_helpdesk
          end
          @available_filters
        end
      end

    end
  end
end

unless IssueQuery.included_modules.include?(RedmineHelpdesk::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineHelpdesk::Patches::IssueQueryPatch)
end


