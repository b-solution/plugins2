require File.expand_path('../../test_helper', __FILE__)

# Re-raise errors caught by the controller.
# class HelpdeskMailerController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
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

  include RedmineHelpdesk::TestHelper

  def setup
    RedmineHelpdesk::TestCase.prepare
    ActionMailer::Base.deliveries.clear

    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_show_issue
    issue = Issue.find(1)
    assert_not_nil issue.helpdesk_ticket
    get :show, :id => 1
    assert_response :success
  end

  def test_get_index_with_filters
    ticket = HelpdeskTicket.find(1)
    ticket.save

    @request.session[:user_id] = 1
    get :index, :set_filter =>"1",
      :f => ["ticket_reaction_time", ""],
      :op => {"ticket_reaction_time" => ">="},
      :v => {"ticket_reaction_time"=>["10"]},
      :c => ["customer", "ticket_source", "customer_company", "helpdesk_ticket", "ticket_reaction_time", "ticket_first_response_time", "ticket_resolve_time"],
      :project_id => "ecookbook"
    assert_response :success
  end

  def test_get_vote_issues
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')

    @request.session[:user_id] = 1
    get :index, :set_filter =>"1",
      :f => ["vote", ""],
      :op => { "vote" => "*" },
      :c => ["tracker", "vote", "vote_comment"],
      :project_id => "ecookbook"
    assert_response :success
    assert_select "table.list.issues td.vote span", /Just ok/
    assert_select "table.list.issues td.vote_comment p", /Good/
  end

  def test_get_not_vote_issues
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')

    @request.session[:user_id] = 1
    get :index, :set_filter =>"1",
      :f => ["vote", ""],
      :op => { "vote" => "!*" },
      :c => ["tracker", "vote", "vote_comment"],
      :project_id => "ecookbook"
    assert_response :success
    assert_select "table.list.issues td.vote", ""
  end

  def test_get_only_bad_voted_issues
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')
    ticket = HelpdeskTicket.find(2)
    ticket.update_attributes(:vote => 0, :vote_comment => 'Bad!')

    @request.session[:user_id] = 1
    get :index, :set_filter =>"1",
      :f => ["vote", ""],
      :op => { "vote" => "=" },
      :v => { "vote" => ["0"] },
      :c => ["tracker", "vote", "vote_comment"],
      :project_id => "ecookbook"
    assert_response :success
    assert_select "table.list.issues td.vote span", /Not good/
    assert_select "table.list.issues td.vote_comment p", /Bad/
    assert_select "table.list.issues td.vote span" do |votes|
      votes.each do |vote|
        assert_match /^((?!Just ok).)*/, vote.to_s
      end
    end
  end

  def test_get_tickets_as_csv
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')
    ticket = HelpdeskTicket.find(2)
    ticket.update_attributes(:vote => 0, :vote_comment => 'Bad!')

    @request.session[:user_id] = 1
    get :index, :set_filter =>"1",
      :f => ["vote", ""],
      :op => { "vote" => "=" },
      :v => { "vote"=>["1", "0"] },
      :c => ["tracker", "vote", "vote_comment", "last_message", "last_message_date", "customer", "ticket_source", "customer_company", "helpdesk_ticket", "ticket_reaction_time", "ticket_first_response_time", "ticket_resolve_time"],
      :project_id => "ecookbook"
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal "text/csv; header=present", @response.content_type
    assert @response.body.starts_with?("#,")
  end

  def test_should_send_note
    user = User.find(1)
    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
  end

  def test_should_calculate_metrics
    @request.session[:user_id] = 1

    issue = Issue.find(1)
    issue.journals.destroy_all

    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => {:notes => 'Response to customer'}

    issue.reload
    assert_not_nil issue.helpdesk_ticket.first_response_time
    assert (issue.helpdesk_ticket.reaction_time - issue.helpdesk_ticket.first_response_time) < 100
  end

  def test_should_forward_note
    user = User.find(1)
    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :journal_message => {:to_address => "jsmith@somenet.foo"},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_match "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user
    assert_equal Contact.find(4), j.journal_message.contact

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal "jsmith@somenet.foo", mail.to.first
  end

  def test_should_send_note_with_bcc
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :journal_message => {:bcc_address => "mail1@mail.com, mail2@mail.com"},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
    assert_equal ["mail1@mail.com", "mail2@mail.com"].sort, mail.bcc.sort
  end

  def test_should_not_send_note_with_cc
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :journal_message => {:cc_address => "mail3@mail.com, mail4@mail.com"},
         :issue => {:notes => notes}
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
    assert_equal ["mail3@mail.com", "mail4@mail.com"].sort, mail.cc.sort
    assert mail.bcc.empty?, "Bcc should be empty"
  end

  def test_should_send_note_with_attachments
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = user.id
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => {:notes => notes},
         :attachments => {'1' => {'file' => helpdesk_uploaded_file('attachment.zip', 'application/octet-stream')}}
    mail = last_ticket_mail
    assert_not_nil mail.attachments
    assert_equal 3855, mail.attachments.first.decoded.size
  end

  def test_should_send_note_issue_from_anonymous
    issue = Issue.find(1)
    issue.author_id = 6
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                              :issue => issue,
                                              :from_address => contact.primary_email,
                                              :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
  end

  def test_should_create_ticket
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_difference 'HelpdeskTicket.count' do
      post :create,
           :issue => {:tracker_id => 3, :subject => "test", :status_id => 2, :priority_id => 5,
                      :helpdesk_ticket_attributes => {:contact_id => 1,
                                                      :source => "0",
                                                      :ticket_date => "2013-01-01 01:01:01 +0400"}},
           :project_id => project
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    assert_not_nil Issue.last.helpdesk_ticket
  end

  def test_should_send_auto_answer
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_difference 'HelpdeskTicket.count' do
      post :create,
           :issue => {:tracker_id => 3, :subject => "test", :status_id => 2,
                      :priority_id => 5, :description => "test description",
                      :helpdesk_ticket_attributes => {:contact_id => 1,
                                                      :source => "0",
                                                      :ticket_date => "2013-01-01 01:01:01 +0400"}},
           :helpdesk_send_as => HelpdeskTicket::SEND_AS_NOTIFICATION,
           :project_id => 1
    end
    mail = last_ticket_mail
    assert_mail_body_match "We hereby confirm that we have received your message", mail
  end

  def test_should_send_initial_message
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_difference 'HelpdeskTicket.count' do
      post :create,
           :issue => {:tracker_id => 3, :subject => "test", :status_id => 2,
                      :priority_id => 5, :description => "test initial description",
                      :helpdesk_ticket_attributes => {:contact_id => 1,
                                                      :source => "0",
                                                      :ticket_date => "2013-01-01 01:01:01 +0400"}},
           :helpdesk_send_as => HelpdeskTicket::SEND_AS_MESSAGE,
           :project_id => 1
    end
    mail = last_ticket_mail
    assert_mail_body_match "test initial description", mail
    assert_equal HelpdeskTicket.order('id ASC').last.message_id, mail.message_id
    assert_equal false, HelpdeskTicket.order('id ASC').last.is_incoming
  end

  def test_should_not_create_ticket_for_invalid_issue
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    ActionMailer::Base.deliveries.clear
    put :update,
         :id => 1,
         :helpdesk => {:is_send_mail => 1},
         :issue => { :notes => 'Test notes', :subject => '' }
    assert_equal ActionMailer::Base.deliveries, []
  end

  def test_should_not_create_ticket_with_empty_customer
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_no_difference 'HelpdeskTicket.count' do
      post :create,
           :issue => {:tracker_id => 3, :subject => "Test subject", :status_id => 2, :priority_id => 5,
                      :helpdesk_ticket_attributes => {:source => "0",
                                                      :contact_id => '',
                                                      :ticket_date => "2013-01-01 01:01:01 +0400"}},
           :project_id => project
      if ActiveRecord::VERSION::MAJOR >= 4
        assert_select 'div#errorExplanation', /customer cannot be blank/i
      else
        assert_error_tag :content => /helpdesk_ticket.customer can&#x27;t be blank/i
      end
    end
  end

  def test_put_update_form
    if ActiveRecord::VERSION::MAJOR < 4
      @request.session[:user_id] = 1
      issue = Issue.find(1)
      ContactsSetting[:helpdesk_tracker, issue.project.id] = 2
      xhr :put, :update_form,
                :issue => {:tracker_id => 2,
                           :helpdesk_ticket_attributes => {:contact_id => 3,
                                                           :source => HelpdeskTicket::HELPDESK_PHONE_SOURCE}},
                :helpdesk_send_as => HelpdeskTicket::SEND_AS_MESSAGE,
                :project_id => issue.project
      assert_response :success
      assert_equal 'text/javascript', response.content_type
      assert_template 'update_form'


      issue = assigns(:issue)
      assert_kind_of Issue, issue
      assert_equal 3, issue.helpdesk_ticket.customer.id
      assert_equal HelpdeskTicket::HELPDESK_PHONE_SOURCE, issue.helpdesk_ticket.source
    end
  end

  private

  def last_ticket_mail
    ActionMailer::Base.deliveries.detect{|m| m["X-Redmine-Ticket-ID"]}
  end

end
