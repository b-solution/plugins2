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

require File.dirname(__FILE__) + '/../../test_helper'

class Redmine::ApiTest::OrdersTest < ActiveRecord::VERSION::MAJOR >= 4 ? Redmine::ApiTest::Base : ActionController::IntegrationTest
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
                                                                                                                    :product_categories,
                                                                                                                    :product_lines])

  def setup
    Setting.rest_api_enabled = '1'
    RedmineProducts::TestCase.prepare
  end

  def test_get_orders_xml
    # Use a private project to make sure auth is really working and not just
    # only showing public issues.
    Redmine::ApiTest::Base.should_allow_api_authentication(:get, "/projects/private-child/orders.xml") if ActiveRecord::VERSION::MAJOR < 4

    get '/orders.xml', {}, credentials('admin')

    assert_tag :tag => 'orders',
      :attributes => {
        :type => 'array',
        :total_count => assigns(:orders_count),
        :limit => 25,
        :offset => 0
      }
  end


  def test_post_orders_xml
    parameters = {:order => {:project_id => 1, :number => 'api_test_002',
                             :order_date => Date.today,
                             :project_id => Project.find(1).id,
                             :status_id => OrderStatus.default,
                             :lines_attributes => {"0"=>{:description => "Test", :quantity => 2, :price => 10}}}}
    if ActiveRecord::VERSION::MAJOR < 4
      Redmine::ApiTest::Base.should_allow_api_authentication(:post,
                                      '/orders.xml',
                                      parameters,
                                      {:success_code => :created})
    end

    assert_difference('Order.count') do
      post '/orders.xml', parameters, credentials('admin')
    end

    order = Order.order('id DESC').first
    assert_equal parameters[:order][:number], order.number

    assert_response :created
    assert_equal 'application/xml', @response.content_type
    assert_tag 'order', :child => {:tag => 'id', :content => order.id.to_s}
  end

  def test_put_orders_1_xml
    parameters = {:order => {:number => 'PO_UPDATED'}}

    if ActiveRecord::VERSION::MAJOR < 4
      Redmine::ApiTest::Base.should_allow_api_authentication(:put,
                                    '/orders/1.xml',
                                    parameters,
                                    {:success_code => :ok})
    end

    assert_no_difference('Order.count') do
      put '/orders/1.xml', parameters, credentials('admin')
    end

    order = Order.find(1)
    assert_equal parameters[:order][:number], order.number

  end
  def test_should_post_with_custom_fields
    field = OrderCustomField.create!(:name => 'Test', :field_format => 'int')
    parameters = {:order => {:number => 'PO_NEW',
                             :order_date => Date.today,
                             :project_id => Project.find(1).id,
                             :status_id => OrderStatus.default,
                             :custom_fields => [{'id' => field.id.to_s, 'value' => '12' }],
                             :lines_attributes => {"0"=>{:description => "Test", :quantity => 2, :price => 10}}}}
    assert_difference('Order.count') do
      post '/orders.xml', parameters, credentials('admin')
    end
    order = Order.last
    assert_equal '12', order.custom_value_for(field.id).value
  end

  def test_should_put_with_custom_fields
    field = OrderCustomField.create!(:name => 'Test', :field_format => 'text')
    assert_no_difference('Order.count') do
      put '/orders/1.xml', {:order => {:custom_fields => [{'id' => field.id.to_s, 'value' => 'Hello' }]}}, credentials('admin')
    end
    order = Order.find(1)
    assert_equal 'Hello', order.custom_value_for(field.id).value
  end

end
