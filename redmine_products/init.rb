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

require 'redmine'
require 'redmine_products'

PRODUCTS_VERSION_NUMBER = '2.0.0'
PRODUCTS_VERSION_TYPE = "PRO version"


Redmine::Plugin.register :redmine_products do
  name "Redmine Products plugin (#{PRODUCTS_VERSION_TYPE})"
  author 'RedmineCRM'
  description 'Plugin for managing products and orders'
  version PRODUCTS_VERSION_NUMBER
  url 'http://redminecrm.com/projects/products'
  author_url 'mailto:support@redminecrm.com'

  requires_redmine :version_or_higher => '2.3'
  begin
    requires_redmine_plugin :redmine_contacts, :version_or_higher => '4.0.0'
  rescue Redmine::PluginNotFound  => e
    raise "Please install redmine_contacts plugin"
  end

  settings :default => {
    :orders_show_in_top_menu => true,
    :products_show_in_top_menu => true
  }, :partial => 'settings/products/products'

  project_module :products do
    permission :view_products, :products => [:index, :show, :context_menu]
    permission :add_products, :products => [:new, :create]
    permission :edit_products, :products => [:new, :create, :edit, :update, :bulk_update]
    permission :delete_products, :products => [:destroy, :bulk_destroy]
    permission :import_products, {:product_imports => [:new, :create]}
    permission :save_products_queries, {}, :require => :loggedin
    permission :manage_public_products_queries, {}, :require => :member
  end

  project_module :orders do
    permission :view_orders, :orders => [:index, :show, :context_menu]
    permission :add_orders, {:orders => [:new, :create], :products => [:add]}
    permission :edit_orders, {:orders => [:new, :create, :edit, :update, :bulk_update], :products => [:add]}
    permission :delete_orders, :orders => [:destroy, :bulk_destroy]
    permission :comment_orders, :order_comments => [:create, :destroy]
    permission :import_orders, {:order_imports => [:new, :create]}
    permission :save_orders_queries, {}, :require => :loggedin
    permission :manage_public_orders_queries, {}, :require => :member
  end

  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |map|
      map.permission :manage_product_relations, {:products_issues => [:new, :add, :destroy, :autocomplete_for_product]}
    end
  end

  menu :top_menu, :products,
                          {:controller => 'products', :action => 'index', :project_id => nil},
                          :caption => :label_product_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'products', :action => 'index'},
                                          nil, {:global => true})  && ProductsSettings.products_show_in_top_menu? }
  menu :top_menu, :orders,
                          {:controller => 'orders', :action => 'index', :project_id => nil},
                          :caption => :label_order_plural,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'orders', :action => 'index'},
                                          nil, {:global => true}) && ProductsSettings.orders_show_in_top_menu? }

  menu :application_menu, :products,
                          {:controller => 'products', :action => 'index', :project_id => nil},
                          :caption => :label_product_plural,
                          :param => :project_id,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'products', :action => 'index'},
                                          nil, {:global => true})  && ProductsSettings.products_show_in_app_menu? }
  menu :application_menu, :orders,
                          {:controller => 'orders', :action => 'index', :project_id => nil},
                          :caption => :label_order_plural,
                          :param => :project_id,
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'orders', :action => 'index'},
                                          nil, {:global => true}) && ProductsSettings.orders_show_in_app_menu? }

  menu :project_menu, :products, {:controller => 'products', :action => 'index'}, :caption => :label_product_plural, :param => :project_id
  menu :project_menu, :orders, {:controller => 'orders', :action => 'index'}, :caption => :label_order_plural, :param => :project_id

  menu :admin_menu, :products, {:controller => 'settings', :action => 'plugin', :id => "redmine_products"}, :caption => :label_product_plural

  activity_provider :products, :default => false, :class_name => ['Product']
  activity_provider :orders, :default => false, :class_name => ['Order']

end
