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
  module Hooks
    class ViewsInvoicesHook < Redmine::Hook::ViewListener
      render_on :edit_invoices_form_lines_actions, :partial => "invoices/new_product_line"

      def edit_invoices_form_details_bottom(context={})
        return javascript_tag "observeAutocompleteField('invoice_order_number', '#{escape_javascript auto_complete_orders_path }')"
      end

      def view_invoices_show_lines_bottom(context={})
        if order = context[:invoice] && context[:invoice].order_number && Order.visible.where(:number => context[:invoice].order_number).first
          order_link = link_to order.number, order_path(order)
          return javascript_tag "$('td.oder-number').html('#{escape_javascript order_link}');"
        end
      end

    end
  end
end
