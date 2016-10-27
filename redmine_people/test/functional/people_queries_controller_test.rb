# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2016 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class PeopleQueriesControllerTest < ActionController::TestCase
  fixtures :users, :members, :member_roles, :roles

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                            [:people_information, :departments, :queries, :custom_fields, :custom_values])
  
  def setup
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
  end

  def test_delete_without_deny
    @request.session[:user_id] = 2
    delete :destroy, :id => 1
    assert_response 403
  end

  def test_post_create_people_public_query_without_permission
    @request.session[:user_id] = 2
    query_params = {"name" => "test_new_public_people_query", "visibility" => "2"}

    post :create,
         :default_columns => '1',
         :f => ["firstname", "lastname"],
         :op => {"firstname" => "=", "lastname" => "="},
         :v => { "firstname" => ["Ivan"], "lastname" => ["Ivanov"]},
         :query => query_params

    q = PeopleQuery.find_by_name('test_new_public_people_query')
    assert_redirected_to :controller => 'people' , :action => 'index', :query_id => q.id
    assert (not q.is_public?)
  end

  def test_edit_people_public_query_without_permission
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response 403
  end

  def test_get_new_people_query
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    assert_template 'new'

    att = { :type => 'checkbox',
            :name => 'query_is_for_all',
            :checked => nil,
            :disabled => nil }
    assert_select 'input', :attributes => att
  end

  def test_post_create_people_public_query
    @request.session[:user_id] = 1

    query_params = {"name" => "test_new_public_people_query", "visibility" => "2"}

    post :create,
         :default_columns => '1',
         :f => ["firstname", "lastname"],
         :op => {"firstname" => "=", "lastname" => "="},
         :v => { "firstname" => ["Ivan"], "lastname" => ["Ivanov"]},
         :query => query_params

    q = PeopleQuery.find_by_name('test_new_public_people_query')
    assert_redirected_to :controller => 'people' , :action => 'index', :query_id => q.id
    assert q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end

  def test_post_create_private_query
    @request.session[:user_id] = 1

    query_params = {"name" => "test_new_public_people_query", "visibility" => "0"}

    post :create,
         :default_columns => '1',
         :f => ["firstname", "lastname"],
         :op => {"firstname" => "=", "lastname" => "="},
         :v => { "firstname" => ["Ivan"], "lastname" => ["Ivanov"]},
         :query => query_params

    q = PeopleQuery.find_by_name('test_new_public_people_query')
    assert_redirected_to :controller => 'people' , :action => 'index', :query_id => q.id
    assert !q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end

  def test_put_update_public_query
    @request.session[:user_id] = 1

    query_params = {"name" => "test_edit_public_query", "visibility" => "2"}

    post :create,
         :default_columns => '1',
         :f => ["firstname", "lastname"],
         :op => {"firstname" => "=", "lastname" => "="},
         :v => { "firstname" => ["Ivan"], "lastname" => ["Ivanov"]},
         :query => query_params

    q = PeopleQuery.find_by_name('test_edit_public_query')
    assert_redirected_to :controller => 'people' , :action => 'index', :query_id => q.id
    assert q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end

  def test_delete_destroy
    @request.session[:user_id] = 1
    delete :destroy, :id => 2
    assert_redirected_to :controller => 'people_queries', :set_filter => '1'
    assert_nil Query.find_by_id(2)
  end

end
