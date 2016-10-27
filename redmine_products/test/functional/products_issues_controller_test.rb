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

class ProductsIssuesControllerTest < ActionController::TestCase
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
                                                                                                                    :products_issues,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines])

  def setup
    RedmineProducts::TestCase.prepare
  end

  def test_autocomplete_for_product
    @request.session[:user_id] = 1
    xhr :get, :autocomplete_for_product, :q => 'crm', :issue_id => '1' , :project_id => 'ecookbook'
    assert_response :success
    assert_select 'input', :count => 1
    assert_select 'input[name=?][value=2]', 'products_issue[product_ids][]'
  end

  def test_new
    @request.session[:user_id] = 1
    xhr :get, :new, :issue_id => '1'
    assert_response :success
    assert_match /ajax-modal/, response.body
  end

  def test_create_multiple
    @request.session[:user_id] = 1
    xhr :post, :add, :issue_id => '2', :products_issue => {:product_ids => ['3', '4']}
    assert_response :success
    assert_match /products_inputs/, response.body
    assert_match /Helpdesk/, response.body
    assert_match /People/, response.body
  end

end
