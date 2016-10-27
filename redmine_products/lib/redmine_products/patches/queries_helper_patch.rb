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

require_dependency 'queries_helper'

module RedmineProducts
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :column_value, :products
        end
      end


      module InstanceMethods
        # include ContactsHelper

        def column_value_with_products(column, list_object, value)
          if [:order_number, :order_subject].include?(column.name) && list_object.is_a?(Order)
            link_to(h(value), order_path(list_object))
          elsif column.name == :order_amount && list_object.is_a?(Order)
            list_object.amount_to_s
          elsif column.name == :price && list_object.is_a?(Product)
            list_object.price_to_s
          elsif [:code, :name].include?(column.name) && list_object.is_a?(Product)
            link_to(h(value), product_path(list_object))
          elsif value.is_a?(Order)
            order_tag(value, :no_contact => true, :plain => true, :size => 16)
          elsif value.is_a?(Product)
            product_tag(value, :no_contact => true, :plain => true, :size => 16)
          else
            column_value_without_products(column, list_object, value)
          end
        end

      end

    end
  end
end

unless QueriesHelper.included_modules.include?(RedmineProducts::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineProducts::Patches::QueriesHelperPatch)
end
