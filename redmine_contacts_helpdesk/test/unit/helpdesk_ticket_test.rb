require File.expand_path('../../test_helper', __FILE__)

class HelpdeskTicketTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :contacts_issues,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets])

  def test_should_calculate_reaction_date_from_first_journal
    helpdesk_ticket = HelpdeskTicket.find(1)
    issue = helpdesk_ticket.issue
    journal_message = issue.journals.order(:created_on).last.build_journal_message(:contact_id => helpdesk_ticket.customer, :to_address => helpdesk_ticket.customer.primary_email)
    journal_message.save
    helpdesk_ticket.reload

    helpdesk_ticket.calculate_metrics
    assert_equal 2, issue.journals.count
    assert_equal helpdesk_ticket.reaction_time, issue.journals.order(:created_on).first.created_on - helpdesk_ticket.ticket_date.utc
  end
end
