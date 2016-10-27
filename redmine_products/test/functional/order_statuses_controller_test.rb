# encoding: utf-8
#
# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class OrderStatusesControllerTest < ActionController::TestCase
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

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines])

  def test_index_by_anonymous_should_redirect_to_login_form
    @request.session[:user_id] = nil
    get :index
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Forder_statuses'
  end

  def test_should_get_new
    @request.session[:user_id] = 1
    get :new
    assert_response :success
    assert_template 'new'
    # assert_not_nil Issue.find_by_subject("test subject")
  end

  def test_get_edit
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:order_status)
    assert_equal OrderStatus.find(1), assigns(:order_status)
  end

  def test_put_update
    @request.session[:user_id] = 1
    status1 = OrderStatus.find(1)
    old_name = status1.name
    new_name = "updated main"
    put :update, :id => 1, :order_status => {:name => new_name, :color_name=>"#000000"}
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_products", :tab => "order_statuses"
    status1.reload
    assert_equal new_name, status1.name
  end

  def test_destroy
    @request.session[:user_id] = 1
    Order.delete_all("status_id = 1")

    assert_difference 'OrderStatus.count', -1 do
      delete :destroy, :id => '1'
    end
    assert_redirected_to :controller => 'settings', :action => 'plugin', :id => "redmine_products", :tab => "order_statuses"
    assert_nil OrderStatus.where(:id => 1).first
  end

end
