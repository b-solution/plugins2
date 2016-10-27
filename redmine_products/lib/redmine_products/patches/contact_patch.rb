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
    module ContactPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          has_many :orders, :dependent => :nullify
          has_many :product_lines, :through => :orders, :source => :lines
          has_many :products, :through => :product_lines, :uniq => true
        end
      end

      module InstanceMethods
        # Adds a rates tab to the user administration page
        def orders_balance
          scope = self.orders.visible
          scope = scope.where(:contact_id => self.id) unless self.blank?
          @orders_balance ||= scope.open.group(:currency).sum(:amount)
        end



      end

    end
  end
end

unless Contact.included_modules.include?(RedmineProducts::Patches::ContactPatch)
  Contact.send(:include, RedmineProducts::Patches::ContactPatch)
end
