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

class RedmineProducts::AutoCompletesControllerTest < ActionController::TestCase
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

  def setup
    RedmineProducts::TestCase.prepare
    @controller = AutoCompletesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = 1
  end

  def test_products_should_not_be_case_sensitive
    get :products, :q => 'invoices'
    assert_response :success
    assert_not_nil assigns(:products)
    assert assigns(:products).detect {|product| product.name.match /Invoices/}
  end

  def test_products_should_accept_term_param
    assert_equal 'Invoices', Product.live_search('invoices').first.name
    get :products, :term => 'invoices'
    assert_response :success
    assert_not_nil assigns(:products)
    assert assigns(:products).detect {|product| product.name.match /Invoices/}
  end

  def test_orders_should_not_be_case_sensitive
    get :orders, :q => 'sales order'
    assert_response :success
    assert_not_nil assigns(:orders)
    assert assigns(:orders).detect {|order| order.subject.match /Sales order/}
  end

  def test_products_should_return_json
    get :products, :q => 'invoices'
    assert_response :success
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Array, json
    product = json.last
    assert_kind_of Hash, product
    assert_equal 2, product['id']
    assert_equal "2", product['value']
    assert_equal 'Invoices', product['name']
  end

  def test_orders_should_return_json
    get :orders, :q => 'sales order'
    assert_response :success
    json = ActiveSupport::JSON.decode(response.body)
    assert_kind_of Array, json
    order = json.first
    assert_kind_of Hash, order
  end
end
