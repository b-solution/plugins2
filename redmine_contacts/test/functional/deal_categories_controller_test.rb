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

class DealCategoriesControllerTest < ActionController::TestCase
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
                                                                                                                    :deal_statuses,
                                                                                                                    :deal_categories,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  def setup
    RedmineContacts::TestCase.prepare

    @controller = DealCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1
  end

  def test_get_new
    @request.session[:user_id] = 1
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    # assert_not_nil Issue.find_by_subject("test subject")
  end

  def test_get_edit
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:category)
    assert_equal DealCategory.find(1), assigns(:category)
  end

  def test_put_update
    @request.session[:user_id] = 1
    category1 = DealCategory.find(1)
    old_name = category1.name
    new_name = "updated main"
    put :update, :id => 1, :category => {:name => new_name}
    assert_redirected_to '/projects/ecookbook/settings/deals'
    category1.reload
    assert_equal new_name, category1.name
  end

  def test_destroy_category_not_in_use
    delete :destroy, :id => 2
    assert_redirected_to '/projects/ecookbook/settings/deals'
    assert_nil DealCategory.find_by_id(2)
  end

  def test_destroy_category_in_use
    delete :destroy, :id => 1
    assert_response :success
    assert_template 'destroy'
    assert_not_nil DealCategory.find_by_id(1)
  end

  def test_destroy_category_in_use_with_reassignment
    deal = Deal.where(:category_id => 1).first
    delete :destroy, :id => 1, :todo => 'reassign', :reassign_to_id => 2
    assert_redirected_to '/projects/ecookbook/settings/deals'
    assert_nil DealCategory.find_by_id(1)
    # check that the issue was reassign
    assert_equal 2, deal.reload.category_id
  end

  def test_destroy_category_in_use_without_reassignment
    deal = Deal.where(:category_id => 1).first
    delete :destroy, :id => 1, :todo => 'nullify'
    assert_redirected_to '/projects/ecookbook/settings/deals'
    assert_nil DealCategory.find_by_id(1)
    # check that the issue category was nullified
    assert_nil deal.reload.category_id
  end

end
