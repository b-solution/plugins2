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

require_dependency 'auto_completes_controller'

module RedmineProducts
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          helper :products
        end
      end

      module InstanceMethods
        def products
          @products = []
          q = (params[:q] || params[:term]).to_s.strip
          scope = Product.visible
          scope = scope.includes(:image).limit(params[:limit] || 10)
          scope = scope.live_search(q) unless q.blank?
          @products = scope.order("#{Product.table_name}.name")

          render :layout => false, :partial => 'products'
        end


        def orders
          @orders = []
          q = (params[:q] || params[:term]).to_s.strip
          scope = Order.visible
          scope = scope.limit(params[:limit] || 10)
          scope = scope.where(:currency => params[:currency]) if params[:currency]
          scope = scope.where(:status_id => params[:status_id]) if params[:status_id]
          scope = scope.where(:project_id => params[:project_id]) if params[:project_id]
          scope = scope.live_search(q) unless q.blank?
          @orders = scope.order(:number)
          render :text => @orders.map {|order| {
                                                'id' => order.id,
                                                'number' => order.number,
                                                'label' => "##{order.number}#{' - ' + order.subject unless order.subject.blank?}#{' (' + order.amount_to_s + ')' unless order.amount.blank? }".html_safe,
                                                'name' => order.subject,
                                                'amount' => order.amount_to_s,
                                                'currency' => order.currency,
                                                'value' => order.number
                                                }
                                              }.to_json

        end

      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineProducts::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineProducts::Patches::AutoCompletesControllerPatch)
end
