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

class OrderStatusesController < ApplicationController
  unloadable
  layout 'admin'

  before_filter :require_admin, :except => :index
  before_filter :require_admin_or_api_request, :only => :index
  accept_api_auth :index

  def index
    respond_to do |format|
      format.api {
        @order_statuses = OrderStatus.all(:order => 'position')
      }
    end
  end

  def new
    @order_status = OrderStatus.new
  end

  def create
    @order_status = OrderStatus.new(params[:order_status])
    if request.post? && @order_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'order_statuses'
    else
      render :action => 'new'
    end
  end

  def edit
    @order_status = OrderStatus.find(params[:id])
  end

  def update
    @order_status = OrderStatus.find(params[:id])
    if request.put? && @order_status.update_attributes(params[:order_status])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'order_statuses'
    else
      render :action => 'edit'
    end
  end

  def destroy
    OrderStatus.find(params[:id]).destroy
    redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'order_statuses'
  rescue
    flash[:error] = l(:error_products_unable_delete_order_status)
    redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'order_statuses'
  end


end
