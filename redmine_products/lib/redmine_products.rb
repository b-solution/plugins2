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

Rails.configuration.to_prepare do
  require 'redmine_products/hooks/views_issues_hook'
  require 'redmine_products/patches/issue_query_patch'
  require 'redmine_products/hooks/views_custom_fields_hook'
  require 'redmine_products/patches/issue_patch'
  require 'redmine_products/patches/custom_fields_helper_patch'
  require 'redmine_products/patches/invoices_controller_patch'
  require 'redmine_products/hooks/views_invoices_hook'
  require 'redmine_products/hooks/views_contacts_hook'
  require 'redmine_products/patches/add_helpers_for_products_patch'
  require 'redmine_products/patches/contact_patch'
  require 'redmine_products/patches/project_patch'
  require 'redmine_products/patches/contacts_helper_patch'
  require 'redmine_products/patches/queries_helper_patch'
  require 'redmine_products/patches/notifiable_patch'
  require 'redmine_products/patches/auto_completes_controller_patch'

  require 'redmine_products/hooks/views_layouts_hook'
  require 'redmine_products/hooks/controller_contacts_duplicates_hook'
end

module ProductsSettings

  def self.invoices_plugin_installed?
    @@invoices_plugin_installed ||= (Redmine::Plugin.installed?(:redmine_contacts_invoices) && Redmine::Plugin.find(:redmine_contacts_invoices).version >= "2.2.3" )
  end

  def self.products_show_in_top_menu?
  	!!Setting.plugin_redmine_products[:products_show_in_top_menu]
  end

  def self.cross_project_contacts?
    !!Setting.plugin_redmine_products[:cross_project_contacts]
  end

  def self.select_companies
    Setting.plugin_redmine_products[:select_companies].to_i > 0
  end

  def self.orders_show_in_top_menu?
  	!!Setting.plugin_redmine_products[:orders_show_in_top_menu]
  end

  def self.products_show_in_app_menu?
    !!Setting.plugin_redmine_products[:products_show_in_app_menu]
  end

  def self.orders_show_in_app_menu?
    !!Setting.plugin_redmine_products[:orders_show_in_app_menu]
  end

  def self.default_list_style
  	'list_excerpt'
  end
end
