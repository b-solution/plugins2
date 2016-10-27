# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class HelpdeskVotesControllerTest < ActionController::TestCase
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

  FIXTURES_PATH = Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/helpdesk_mailer'

  def setup
    RedmineHelpdesk::TestCase.prepare
    User.current = nil
    RedmineHelpdesk.settings[:helpdesk_vote_accept] = 1
  end

  def test_should_open_on_correct_token
    get :show, :id => 1, :hash => HelpdeskTicket.find(1).token
    assert_response :success
    assert_match 'Please rate our work', @response.body
  end

  def test_should_show_404_with_incorrect_token
    get :show, :id => 1, :hash => '111111'
    assert_response 404
  end

  def test_should_hide_vote_comment_if_comments_off
    RedmineHelpdesk.settings[:helpdesk_vote_comment_accept] = 0
    get :show, :id => 1, :hash => HelpdeskTicket.find(1).token
    assert_response :success
    assert_match 'Please rate our work', @response.body
    assert_not_match /Leave a comment/, @response.body if self.respond_to?(:assert_not_match)
  end

  def test_should_show_vote_comment_if_comments_off
    RedmineHelpdesk.settings[:helpdesk_vote_comment_accept] = 1
    get :show, :id => 1, :hash => HelpdeskTicket.find(1).token
    assert_response :success
    assert_match 'Please rate our work', @response.body
    assert_match 'Leave a comment', @response.body
  end

  def test_should_save_last_comment_from_ticket
    post :vote, :id => 1, :hash => HelpdeskTicket.find(1).token, :vote => 2, :vote_comment => 'test test'
    assert_response :success
    assert_match 'Thank you for voting', @response.body
    assert_equal(2, HelpdeskTicket.find(1).vote)
    assert_equal('test test', HelpdeskTicket.find(1).vote_comment)
  end

  def test_fast_vote_should_update_ticket_if_comments_off
    RedmineHelpdesk.settings[:helpdesk_vote_comment_accept] = 0
    get :fast_vote, :id => 1, :vote => 1, :hash => HelpdeskTicket.find(1).token
    assert_response :success
    assert_match 'Thank you for voting', @response.body
    assert_equal(1, HelpdeskTicket.find(1).vote)
  end

  def test_fast_vote_should_open_vote_page_if_comments_on
    RedmineHelpdesk.settings[:helpdesk_vote_comment_accept] = 1
    get :fast_vote, :id => 1, :vote => 1, :hash => HelpdeskTicket.find(1).token
    assert_response :success
    assert_match 'Please rate our work', @response.body
    if Redmine::VERSION.to_s >= "3.0"
      assert_match 'id="vote_1" value="1" checked="checked"', @response.body
    else
      assert_match 'input checked="checked" id="vote_1"', @response.body
    end

  end

  def test_should_save_votes_in_logs
    RedmineHelpdesk.settings[:helpdesk_vote_save_log] = 1
    post :vote, :id => 1, :hash => HelpdeskTicket.find(1).token, :vote => 1, :vote_comment => 'Test test test'
    assert_response :success
    assert_match 'Thank you for voting', @response.body
    assert_equal(1, HelpdeskTicket.find(1).vote)
    assert_equal(HelpdeskTicket.find(1).issue, Journal.last.journalized)
    assert_equal(1, Journal.last.details.where(:value => '1').count)
    assert_equal(1, Journal.last.details.where(:value => 'Test test test').count)
  end

  def test_vote_journal_save_user_if_he_present
    RedmineHelpdesk.settings[:helpdesk_vote_save_log] = 1
    @request.session[:user_id] = 2
    post :vote, :id => 1, :hash => HelpdeskTicket.find(1).token, :vote => 0
    assert_response :success
    assert_equal(User.find(2), Journal.last.user)
  end

  def test_if_user_not_present_vote_anonymous
    RedmineHelpdesk.settings[:helpdesk_vote_save_log] = 1
    post :vote, :id => 1, :hash => HelpdeskTicket.find(1).token, :vote => 0
    assert_response :success
    assert_equal(User.where(:lastname => 'Anonymous').first, Journal.last.user)
  end

end
