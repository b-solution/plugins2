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

module RedmineProducts
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          has_many :products_issues
          has_many :products, :through => :products_issues, :uniq => true

          # alias_method_chain :copy_from, :products

          accepts_nested_attributes_for :products_issues, :allow_destroy => true

          validate :validate_products_issues

          safe_attributes 'products_issues_attributes',
            :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:manage_product_relations, issue.project) && user.allowed_to?(:view_products, nil, :global => true) }
        end
      end

      module InstanceMethods
        def copy_from_with_products(arg, options={})
          copy_from_without_products(arg, options)
          issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          self.products_issues = issue.products_issues.map{|pi| pi.id = nil; pi.issue_id = nil; pi.dup }
          self
        end

        def validate_products_issues
          errors.add(:products, :taken) unless products_issues.map(&:product_id).uniq.size == products_issues.size
        end

      end

    end

  end
end

unless Issue.included_modules.include?(RedmineProducts::Patches::IssuePatch)
  Issue.send(:include, RedmineProducts::Patches::IssuePatch)
end
