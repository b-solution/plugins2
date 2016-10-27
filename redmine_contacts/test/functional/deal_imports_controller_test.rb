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


require File.expand_path('../../test_helper', __FILE__)

class DealImportsControllerTest < ActionController::TestCase
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
                                                                                                                    :queries])

  def setup
    RedmineContacts::TestCase.prepare
    @controller = DealImportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @csv_file = Rack::Test::UploadedFile.new(redmine_contacts_fixture_files_path + 'deals_correct.csv', 'text/csv')
  end

  test 'should open contact import form' do
    @request.session[:user_id] = 1
    get :new, :project_id => 1
    assert_response :success
    if Redmine::VERSION.to_s >= '3.2'
      assert_select 'form input#file'
    else
      assert_select 'form.new_deal_import'
    end
  end

  test 'should create new import object' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      get :create, :project_id => 1,
                   :file => @csv_file
      assert_response :redirect
      assert_equal Import.last.class, DealKernelImport
      assert_equal Import.last.user, User.find(1)
      assert_equal Import.last.project, 1
      assert_equal Import.last.settings, { 'project' => 1,
                                           'separator' => ',',
                                           'wrapper' => "\"",
                                           'encoding' => 'ISO-8859-1',
                                           'date_format' => '%m/%d/%Y' }
    end
  end

  test 'should open settings page' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = DealKernelImport.new
      import.user = User.find(1)
      import.project = Project.find(1)
      import.file = @csv_file
      import.save!
      get :settings, :id => import.filename, :project_id => 1
      assert_response :success
      assert_select 'form#import-form'
    end
  end

  test 'should show mapping page' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = DealKernelImport.new
      import.user = User.find(1)
      import.settings = { 'project' => 1,
                          'separator' => ';',
                          'wrapper' => "\"",
                          'encoding' => 'UTF-8',
                          'date_format' => '%m/%d/%Y' }
      import.file = @csv_file
      import.save!
      get :mapping, :id => import.filename, :project_id => 1
      assert_response :success
      assert_select '#import_settings_mapping_name'
      assert_select '#import_settings_mapping_currency'
      assert_select 'table.sample-data tr'
      assert_select 'table.sample-data tr td', 'Сделка века'
      assert_select 'table.sample-data tr td', 'Кемска волость'
    end
  end

  test 'should successfully import from CSV with new import' do
    if Redmine::VERSION.to_s >= '3.2'
      @request.session[:user_id] = 1
      import = DealKernelImport.new
      import.user = User.find(1)
      import.settings = { 'project' => 1,
                          'separator' => ';',
                          'wrapper' => "\"",
                          'encoding' => 'UTF-8',
                          'date_format' => '%m/%d/%Y' }
      import.file = @csv_file
      import.save!
      post :mapping, :id => import.filename, :project_id => 1, :import_settings => { :mapping => { :name => 1, :background => 2 } }
      assert_response :redirect
      post :run, :id => import.filename, :project_id => 1, :format => :js
      assert_equal Deal.last.name, 'Сделка века'
      assert_equal Deal.last.background, 'Кемска волость'
    end
  end

end
