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

require_dependency 'custom_fields_helper'

module RedmineOrders
  module Patches

    module CustomFieldsHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :custom_fields_tabs, :order_tab
        end
      end

      module InstanceMethods
        # Adds a rates tab to the user administration page
        def custom_fields_tabs_with_order_tab
          tabs = custom_fields_tabs_without_order_tab
          tabs << {:name => 'OrderCustomField', :partial => 'custom_fields/index', :label => :label_order_plural}
          tabs << {:name => 'ProductCustomField', :partial => 'custom_fields/index', :label => :label_product_plural}
          tabs << {:name => 'ProductLineCustomField', :partial => 'custom_fields/index', :label => :label_products_order_lines}
          return tabs
        end
      end

    end

  end
end

if Redmine::VERSION.to_s > '2.5'
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => 'OrderCustomField', :partial => 'custom_fields/index', :label => :label_order_plural}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => 'ProductCustomField', :partial => 'custom_fields/index', :label => :label_product_plural}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => 'ProductLineCustomField', :partial => 'custom_fields/index', :label => :label_products_order_lines}
else
  unless CustomFieldsHelper.included_modules.include?(RedmineOrders::Patches::CustomFieldsHelperPatch)
    CustomFieldsHelper.send(:include, RedmineOrders::Patches::CustomFieldsHelperPatch)
  end
end
