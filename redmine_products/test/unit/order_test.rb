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

class OrderTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines])

  include Redmine::I18n

  def test_initialize
    order = Order.new
    assert_equal OrderStatus.default, order.status
  end

  def test_create
    order = Order.new( :number => "SO-001",
                       :subject => "New sales order",
                       :project_id => "1",
                       :contact_id => "3",
                       :order_date => "2013-11-04",
                       :status_id => "2",
                       :currency => "USD",
                       :assigned_to_id => "3",
                       :description => "*Order #SO-001 description with textile*",
                       :lines_attributes => {"0" => {:product_id => "4",
                                                     :description => "People plugin with discount",
                                                     :quantity => "2",
                                                     :price => "99",
                                                     :tax => "0.0",
                                                     :discount => "10",
                                                     :_destroy => false,
                                                     :position => ""},
                                 "1383550516006" => {:product_id => "6",
                                                     :description => "Questions plugin with tax",
                                                     :quantity => "1",
                                                     :price => "99",
                                                     :tax => "20",
                                                     :discount => "",
                                                     :_destroy => false,
                                                     :position => ""},
                                 "1383550542085" => {:product_id => "",
                                                     :description => "Delivery",
                                                     :quantity => "1",
                                                     :price => "30",
                                                     :tax => "0.0",
                                                     :discount => "",
                                                     :_destroy => false,
                                                     :position => ""}
                                            }
                      )
    assert order.save!
    order.reload
    assert_equal 19.8, order.tax_amount
    assert_equal 307.20, order.subtotal.round(2)
    assert_equal 3.0, order.total_units
    assert_equal 327.00, order.amount.round(2)
  end
  def test_create_with_custom_fields
    cf_invoice_id = OrderCustomField.create!(:name => 'Invoice ID', :field_format => 'string')
    cf_expire_date = ProductLineCustomField.create!(:name => 'Expire date', :field_format => 'date')

    order = Order.new( :number => "SO-001",
                       :subject => "New sales order",
                       :project_id => "1",
                       :contact_id => "3",
                       :order_date => "2013-11-04",
                       :status_id => "2",
                       :currency => "USD",
                       :assigned_to_id => "3",
                       :description => "*Order #SO-001 description with textile*",
                       :custom_field_values => {cf_invoice_id.id.to_s => 'INV-2013-12-12/1'},
                       :lines_attributes => {"0" => {:product_id => "4",
                                                     :description => "People plugin with discount",
                                                     :quantity => "2",
                                                     :price => "99",
                                                     :tax => "0.0",
                                                     :discount => "10",
                                                     :custom_field_values => {cf_expire_date.id.to_s => '2013-12-12'},
                                                     :_destroy => false,
                                                     :position => ""},
                                 "1383550516006" => {:product_id => "6",
                                                     :description => "Questions plugin with tax",
                                                     :quantity => "1",
                                                     :price => "99",
                                                     :tax => "20",
                                                     :discount => "",
                                                     :_destroy => false,
                                                     :position => ""},
                                 "1383550542085" => {:product_id => "",
                                                     :description => "Delivery",
                                                     :quantity => "1",
                                                     :price => "30",
                                                     :tax => "0.0",
                                                     :discount => "",
                                                     :_destroy => false,
                                                     :position => ""}
                                            }
                      )
    order.lines.each{|l| l.container = order}
    assert order.save
    order.reload
    assert_equal 19.8, order.tax_amount
    assert_equal 307.20, order.subtotal.round(2)
    assert_equal 3.0, order.total_units
    assert_equal 327.00, order.amount.round(2)
    assert_equal 'INV-2013-12-12/1', order.custom_values.where(:custom_field_id => cf_invoice_id.id).first.value
  end

  def test_update_with_custom_fields
    cf_invoice_id = OrderCustomField.create!(:name => 'Invoice ID', :field_format => 'string')
    cf_expire_date = ProductLineCustomField.create!(:name => 'Expire date', :field_format => 'date')
    order = Order.find(1)
    params =  {:number => "SO-002",
                 :subject => "Updated sales order",
                 :project_id => "5",
                 :contact_id => "3",
                 :order_date => "2013-11-04",
                 :status_id => "2",
                 :currency => "EUR",
                 :assigned_to_id => "3",
                 :description => "Order #SO-002 description with textile",
                 :custom_field_values => {cf_invoice_id.id.to_s => 'INV-2013-12-12/2'},
                 :lines_attributes => {"0" => {:id => 6,
                                               :product_id => "4",
                                               :description => "People plugin with discount",
                                               :quantity => "2",
                                               :price => "20",
                                               :tax => "0.0",
                                               :discount => "10",
                                               # :custom_field_values => {cf_expire_date.id.to_s => '2018-01-01'},
                                               :_destroy => false,
                                               :position => ""},
                                      "1" => {:id => "11", :_destroy => "1"},
                                      "2" => {:id => "12", :_destroy => "1"},
                                      "3" => {:id => "16", :_destroy => "1"},
                                      "4" => {:id => "21", :_destroy => "1"},
                          "1383550542085" => {:product_id => "",
                                               :description => "Delivery",
                                               :quantity => "1",
                                               :price => "30",
                                               :tax => "0.0",
                                               :discount => "",
                                               :_destroy => false,
                                               :position => ""}
                                      }
                 }
    assert order.update_attributes(params)
    order.reload
    assert_equal 'INV-2013-12-12/2', order.custom_values.where(:custom_field_id => cf_invoice_id.id).first.value
  end
end
