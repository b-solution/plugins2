# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class ContactsControllerTest < ActionController::TestCase
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

  RedmineContacts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :contacts_issues,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries,
                                                                                                                    :addresses])

  def setup
    RedmineContacts::TestCase.prepare

    @controller = ContactsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  test "should get index" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    assert_not_nil Contact.find(1)
    get :index
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:contacts)
    assert_not_nil assigns(:tags)
    assert_nil assigns(:project)
    assert_select 'a', :html => /Domoway/
    assert_select 'a', :html => /Marat/
    assert_select 'h3', :html => /Tags/
    assert_select 'h3', :html => /Recently viewed/
    assert_select 'div#tags span#single_tags span.tag-label-color a', "test (3)"
    assert_select 'div#tags span#single_tags span.tag-label-color a', "main (2)"
    # assert_select 'div#tags span#single_tags span.tag-label-color a', { :count => 2, :text =>/(test (2)|main (2))/}
    #   assert_select 'a', "main (2)"
    #   assert_select 'a', "test (2)"
    # end


    # private projects hidden
    # assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
    # assert_no_tag :tag => 'a', :content => /Issue on project 2/
    # project column
    # assert_tag :tag => 'th', :content => /Project/
  end

  test "should get index in project" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    get :index, :project_id => 1
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:contacts)
    assert_not_nil assigns(:project)
    assert_select 'a', :html => /Domoway/
    assert_select 'a', :html => /Marat/
    assert_select 'h3', :html => /Tags/
    assert_select 'h3', :html => /Recently viewed/
  end
  test "should get index with filters and sorting" do
    field = ContactCustomField.create!(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
    contact = Contact.find(1)
    contact.custom_field_values = {field.id => "This is custom значение"}
    contact.save

    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    get :index, :sort => "assigned_to,cf_1,last_name,first_name",
                :v => {"first_name"=>["Ivan"]},
                :f => ["first_name", ""],
                :op => {"first_name"=>"~"}
    assert_response :success
    assert_template :index
    assert_not_nil assigns(:contacts)

    assert_select 'div#content div#contact_list table.contacts td.name h1', 'Ivan Ivanov'
  end

  def test_get_index_with_all_fields
    @request.session[:user_id] = 1
    get :index, crm_query_params.merge({:f => ContactQuery.available_columns.map(&:name), :contacts_list_style => "list"})
    assert_response :success
    assert_template :index

    assert_select 'tr#contact-1 td.id a[href=?]', '/contacts/1'
  end

  def test_index_with_short_filters
    @request.session[:user_id] = 1
    to_test = {
      'tags' => {
        'main|test' => { :op => '=', :values => ['main', 'test'] },
        '=main' => { :op => '=', :values => ['main'] },
        '!test' => { :op => '!', :values => ['test'] }},
      'country' => {
        '*' => { :op => '*', :values => [''] },
        '!*' => { :op => '!*', :values => [''] },
        'US|RU' => { :op => '=', :values => ['US', 'RU'] }},
      'first_name' => {
        'Marat' => { :op => '=', :values => ['Marat'] },
        '~Mara' => { :op => '~', :values => ['Mara'] },
        '!~Mara' => { :op => '!~', :values => ['Mara'] }},
      'created_on' => {
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] }},
      'last_note' => {
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] }},
      'has_deals' => {
        'c' => { :op => '=', :values => ['c'] },
        '!c' => { :op => '!', :values => ['c'] }},
      'has_open_issues' => {
        '=4' => { :op => '=', :values => ['4'] },
        '!*' => { :op => '!*', :values => [''] },
        '*' => { :op => '*', :values => [''] }}
    }

    default_filter = { 'status_id' => {:operator => 'o', :values => [''] }}

    to_test.each do |field, expression_and_expected|
      expression_and_expected.each do |filter_expression, expected|
        get :index, :set_filter => 1, field => filter_expression

        assert_response :success
        assert_template 'index'
        assert_not_nil assigns(:contacts)

        query = assigns(:query)
        assert_not_nil query
        assert query.has_filter?(field)
        assert_equal({field => {:operator => expected[:op], :values => expected[:values]}}, query.filters)
      end
    end
  end

  def test_index_sort_by_custom_field
    @request.session[:user_id] = 1
    cf = ContactCustomField.create!(:name => 'Contact test cf', :is_for_all => true, :field_format => 'string')
    CustomValue.create!(:custom_field => cf, :customized => Contact.find(1), :value => 'test_1')
    CustomValue.create!(:custom_field => cf, :customized => Contact.find(2), :value => 'test_2')
    CustomValue.create!(:custom_field => cf, :customized => Contact.find(3), :value => 'test_3')

    get :index, :set_filter => 1, :sort => "cf_#{cf.id},id"
    assert_response :success

    assert_equal [1, 2, 3], assigns(:contacts).select {|contact| contact.custom_field_value(cf).present?}.map(&:id).sort
  end

  test "should not absolute links" do
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    # assert_equal 'localhost', @response.body
    assert_no_match /localhost/, @response.body
  end

  test "should get index deny user in project" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 5

    get :index, :project_id => 1
    assert_response :redirect
    # assert_tag :tag => 'div', :attributes => { :id => "login-form"}
    # assert_select 'div#login-form'
  end

  test "should get index with filters" do
    @request.session[:user_id] = 1
    get :index, :is_company => ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')
    assert_response :success
    assert_template :index
    assert_select 'div#content div#contact_list table.contacts td.name h1 a', 'Domoway'
  end
  test "should get index as csv" do
    field = ContactCustomField.create!(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
    contact = Contact.find(1)
    contact.custom_field_values = {field.id => "This is custom значение"}
    contact.save

    @request.session[:user_id] = 1
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:contacts)
    assert_equal "text/csv; header=present", @response.content_type
    assert_match /Domoway/, @response.body
  end

  test "should get index as VCF" do
    @request.session[:user_id] = 1
    get :index, :format => 'vcf'
    assert_response :success
    assert_not_nil assigns(:contacts)
    assert_equal 'text/x-vcard', @response.content_type
    assert @response.body.starts_with?("BEGIN:VCARD")
    assert_match /^N:;Domoway/, @response.body
  end

  test "should get contacts_notes as csv" do
    @request.session[:user_id] = 1
    get :contacts_notes, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:notes)
    assert_equal "text/csv; header=present", @response.content_type
    assert @response.body.starts_with?("#,")
  end

  def test_get_show
    # log_user('admin', 'admin')
    @request.session[:user_id] = 2
    Setting.default_language = 'en'

    get :show, :id => 3, :project_id => 1
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:contact)
    assert_not_nil assigns(:project)
    assert_select 'h1', :html => /Domoway/
    assert_select 'div#tags_data span.tag-label-color a', 'main'
    assert_select 'div#tags_data span.tag-label-color a', 'test'
    assert_select 'div#tab-placeholder-contacts'
    assert_select 'div#comments div#notes table.note_data td.name h4', 4
    assert_select 'h3', "Recently viewed"
  end

  def test_get_show_with_bigtext_note
    Contact.find(3).notes.create(:content => many_text, :author_id => 1)
    @request.session[:user_id] = 2
    Setting.default_language = 'en'

    get :show, :id => 3, :project_id => 1
    assert_response :success
    assert_template :show
    assert_select '.note a', '(read more)'
  end

  def test_get_show_tab_deals
    @request.session[:user_id] = 2
    Setting.default_language = 'en'

    get :show, :id => 3, :project_id => 1, :tab => "deals"
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:contact)
    assert_not_nil assigns(:project)
    assert_select 'h1', :html => /Domoway/
    assert_select 'div#deals a', "Delevelop redmine plugin"
    assert_select 'div#deals a', "Second deal with contacts"
  end

  test "should get show without deals" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 4
    Setting.default_language = 'en'

    get :show, :id => 3, :project_id => 1, :tab => "deals"
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:contact)
    assert_not_nil assigns(:project)

    assert_select 'div#deals a', {:count => 0, :text => /Delevelop redmine plugin/}
    assert_select 'div#deals a', {:count => 0, :text => /Second deal with contacts/}

  end
  test "should get new" do
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    assert_select 'input#contact_first_name'
  end

  test "should not get new by deny user" do
    @request.session[:user_id] = 4
    get :new, :project_id => 1
    assert_response :forbidden
  end

  test "should post create" do
    @request.session[:user_id] = 1
    assert_difference 'Contact.count' do
      post :create, :project_id => 1,
                    :contact => {
                                :company => "OOO \"GKR\"",
                                :is_company => 0,
                                :job_title => "CFO",
                                :assigned_to_id => 3,
                                :tag_list => "test,new",
                                :last_name => "New",
                                :middle_name => "Ivanovich",
                                :first_name => "Created"}

    end

    assert_redirected_to :controller => 'contacts', :action => 'show', :id => Contact.last.id, :project_id => Contact.last.project

    contact = Contact.where(:first_name => "Created", :last_name => "New", :middle_name => "Ivanovich").first
    assert_not_nil contact
    assert_equal "CFO", contact.job_title
    assert_equal ["new", "test"], contact.tag_list.sort
    assert_equal 3, contact.assigned_to_id
  end
  test "should post create with custom fields" do
    field = ContactCustomField.create!(:name => 'Test', :is_filter => true, :field_format => 'string')
    @request.session[:user_id] = 1
    assert_difference 'Contact.count' do
      post :create, :project_id => 1,
                    :contact => {
                                :company => "OOO \"GKR\"",
                                :is_company => 0,
                                :job_title => "CFO",
                                :assigned_to_id => 3,
                                :tag_list => "test,new",
                                :last_name => "New",
                                :middle_name => "Ivanovich",
                                :first_name => "Created",
                                :custom_field_values => {"#{field.id}" => "contact one"} }

    end
    assert_redirected_to :controller => 'contacts', :action => 'show', :id => Contact.last.id, :project_id => Contact.last.project

    contact = Contact.where(:first_name => "Created", :last_name => "New", :middle_name => "Ivanovich").first
    assert_equal "contact one", contact.custom_field_values.last.value
  end

  test "should not post create by deny user" do
    @request.session[:user_id] = 4
    post :create, :project_id => 1,
        :contact => {
                    :company => "OOO \"GKR\"",
                    :is_company => 0,
                    :job_title => "CFO",
                    :assigned_to_id => 3,
                    :tag_list => "test,new",
                    :last_name => "New",
                    :middle_name => "Ivanovich",
                    :first_name => "Created"}
    assert_response :forbidden
  end

  test "should get edit" do
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:contact)
    assert_equal Contact.find(1), assigns(:contact)
  end

  test "should put update" do
    @request.session[:user_id] = 1

    contact = Contact.find(1)
    old_firstname = contact.first_name
    new_firstname = 'Fist name modified by ContactsControllerTest#test_put_update'

    put :update, :id => 1, :project_id => 1, :contact => {:first_name => new_firstname}
    assert_redirected_to :action => 'show', :id => '1', :project_id => 1
    contact.reload
    assert_equal new_firstname, contact.first_name

  end

  test "should post destroy" do
    @request.session[:user_id] = 1
    post :destroy, :id => 1, :project_id => 'ecookbook'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_equal 0, Contact.where(:id => [1]).count
  end

  test "should bulk destroy contacts" do
    @request.session[:user_id] = 1

    post :bulk_destroy, :ids => [1, 2, 3]
    assert_redirected_to :controller => 'contacts', :action => 'index'

    assert_equal 0, Contact.where(:id => [1, 2, 3]).count
  end

  test "should not bulk destroy contacts by deny user" do
    @request.session[:user_id] = 4
    assert_raises ActiveRecord::RecordNotFound do
      post :bulk_destroy, :ids => [1, 2]
    end

  end

  def test_bulk_edit_mails
    @request.session[:user_id] = 1
    post :edit_mails, :ids => [1, 2]
    assert_response :success
    assert_template 'edit_mails'
    assert_not_nil assigns(:contacts)
  end

  def test_bulk_edit_mails_by_deny_user
    @request.session[:user_id] = 4
    post :edit_mails, :ids => [1, 2]
    assert_response 403
  end

  def test_bulk_send_mails_by_deny_user
    @request.session[:user_id] = 4
    post :send_mails, :ids => [1, 2], :message => "test message", :subject => "test subject"
    assert_response 403
  end

  def test_bulk_send_mails
    ActionMailer::Base.deliveries = []
    @request.session[:user_id] = 1
    post :send_mails, :ids => [2], :from => "test@mail.from", :bcc => "test@mail.bcc", :"message-content" => "Hello %%NAME%%\ntest message", :subject => "test subject"
    mail = ActionMailer::Base.deliveries.last
    note = Note.last
    assert_not_nil mail
    assert_match /Hello Marat/, mail.text_part.body.to_s
    assert_equal "test subject", mail.subject
    assert_equal "test@mail.from", mail.from.first
    assert_equal "test@mail.bcc", mail.bcc.first
    assert_equal "test subject", note.subject
    assert_equal note.type_id, Note.note_types[:email]
    assert_equal "Hello Marat\ntest message", note.content
  end

  test "should bulk edit contacts" do
    @request.session[:user_id] = 1
    post :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'
    assert_not_nil assigns(:contacts)
  end

  test "should not bulk edit contacts by deny user" do
    @request.session[:user_id] = 4
    assert_raises ActiveRecord::RecordNotFound do
      post :bulk_edit, :ids => [1, 2]
    end
  end

  test "should put bulk update " do
    @request.session[:user_id] = 1

    put :bulk_update, :ids => [1, 2],
                      :add_tag_list => 'bulk, edit, tags',
                      :delete_tag_list => 'main',
                      :add_projects_list => ['1', '2', '3'],
                      :delete_projects_list => ['3', '4', '5'],
                      :note => {:content => "Bulk note content"},
                      :contact => {:company => "Bulk company", :job_title => ''}

    assert_redirected_to :controller => 'contacts', :action => 'index', :project_id => nil
    contacts = Contact.find([1, 2])
    contacts.each do |contact|
      assert_equal "Bulk company", contact.company
      tag_list = contact.tag_list #Need for 4 rails
      assert tag_list.include?('bulk')
      assert tag_list.include?('edit')
      assert tag_list.include?('tags')
      assert !tag_list.include?('main')
      assert contact.project_ids.include?(1) && contact.project_ids.include?(2)

      assert_equal "Bulk note content", contact.notes.find_by_content("Bulk note content").content
    end

  end

  test "should not put bulk update by deny user" do
    @request.session[:user_id] = 4

    put :bulk_update, :ids => [1, 2],
                      :add_tag_list => 'bulk, edit, tags',
                      :delete_tag_list => 'main',
                      :note => {:content => "Bulk note content"},
                      :contact => {:company => "Bulk company", :job_title => ''}
    assert_response 403
  end
  test "should get contacts notes" do
    # log_user('admin', 'admin')
    @request.session[:user_id] = 2

    get :contacts_notes
    assert_response :success
    assert_template :contacts_notes
    assert_select 'h2', /All notes/
    assert_select 'div#contacts_notes table.note_data div.note.content.preview', /Note 1/
  end

  test "should get context menu" do
    @request.session[:user_id] = 1
    xhr :get, :context_menu, :back_url => "/projects/contacts-plugin/contacts", :project_id => 'ecookbook', :ids => ['1', '2']
    assert_response :success
    assert_template 'context_menu'
  end

  test "should post index live search" do
    @request.session[:user_id] = 1
    xhr :post, :index, :search => "Domoway"
    assert_response :success
    assert_template 'contacts/_list_excerpt'
    assert_select 'a', :html => /Domoway/
  end

  test "should post index live search in project" do
    @request.session[:user_id] = 1
    xhr :post, :index, :search => "Domoway", :project_id => 'ecookbook'
    assert_response :success
    assert_template 'contacts/_list_excerpt'
    assert_select 'a', :html => /Domoway/
  end

  test "should post contacts_notes live search" do
    @request.session[:user_id] = 1
    xhr :post, :contacts_notes, :search_note => "Note 1"
    assert_response :success
    assert_template '_notes_list'
    assert_select 'table.note_data div.note.content.preview', /Note 1/
    assert_select 'table.note_data div.note.content.preview', {:count => 0, :text => /Note 2/}
  end

  test "should post contacts_notes live search in project" do
    @request.session[:user_id] = 1
    xhr :post, :contacts_notes, :search_note => "Note 2", :project_id => 'ecookbook'
    assert_response :success
    assert_template '_notes_list'
    assert_select 'table.note_data div.note.content.preview', /Note 2/
  end
  test 'should have import CSV link for user authorized to' do
    @request.session[:user_id] = 1
    get :index, :project_id => 1
    assert_response :success
    assert_select 'a#import_from_csv'
  end

  test 'should not have import CSV link for user not authorized to' do
    @request.session[:user_id] = 4
    get :index, :project_id => 1
    assert_response :success
    assert_select 'a#import_from_csv', false, 'Should not see CSV import link'
  end

  test 'should render tab partial on call to load_tab' do
    @request.session[:user_id] = 4
    xhr :get, :load_tab, :id => 3, :tab_name => 'notes', :partial => 'notes', :format => :js
    assert_template 'contacts/_notes'
  end

  test "should create with avatar" do
    image = Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/files/image.jpg'
    avatar = Rack::Test::UploadedFile.new(image, "image/jpeg")
    @request.session[:user_id] = 1
    assert_difference 'Contact.count' do
      post :create, :project_id => 1,
                    :contact_avatar => { :file => avatar },
                    :contact => {:last_name => "Testov",
                                 :middle_name => "Test",
                                 :first_name => "Testovich"}

    end

    assert_redirected_to :controller => 'contacts', :action => 'show', :id => Contact.last.id, :project_id => Contact.last.project
    assert_equal "Contact", Attachment.last.container_type
    assert_equal Contact.last.id, Attachment.last.container_id

    assert_equal "image.jpg", Attachment.last.diskfile[/image\.jpg/]
  end

  def test_last_notes_for_contact
    contact = Contact.find(1)
    note = contact.notes.create(:content => "note for contact", :author_id => 1)
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_select '.note.content', :text => note.content
  end

  private

  def crm_query_params
    {:set_filter => "1", :project_id => "ecookbook"}
  end

  def many_text
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit.
     In justo urna, faucibus eu fringilla in, lobortis in libero.
     Donec nec eros a dui fermentum aliquam quis sit amet mauris. Fusce ac rutrum erat.
     Sed porta tristique leo eget placerat. Aenean vitae viverra odio, at congue ante.
     Integer purus est, tempus eu neque vitae, facilisis faucibus massa. Maecenas pretium auctor commodo.
     Ut condimentum euismod arcu vel fringilla.
     Interdum et malesuada fames ac ante ipsum primis in faucibus. Mauris id volutpat lorem.
     Mauris sed ipsum ut tortor semper pellentesque non eleifend eros.
     Ut eget est ac dui rhoncus hendrerit vitae eu urna. Phasellus ut convallis tortor, et aliquam odio.
     Proin nec tortor porttitor justo malesuada interdum sit amet ac eros. Vivamus vel bibendum ipsum, ut tincidunt sem.
     Pellentesque imperdiet ligula id nunc finibus posuere. Proin eu urna fringilla, vestibulum erat dictum, pharetra nisi.
     Nulla gravida sapien metus, nec dignissim lectus scelerisque vitae. Nam quis congue nulla.'
  end
end
