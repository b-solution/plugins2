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
    module InvoicesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          skip_before_filter :authorize, :only => :add_product_line
        end
      end

      module InstanceMethods
        def add_product_line
          @project = Project.find(params[:project_id])
          raise Unauthorized unless User.current.allowed_to?(:edit_invoices, @project)
          @product = Product.visible.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end

if ProductsSettings.invoices_plugin_installed?
  unless InvoicesController.included_modules.include?(RedmineProducts::Patches::InvoicesControllerPatch)
    InvoicesController.send(:include, RedmineProducts::Patches::InvoicesControllerPatch)
  end
end
