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

class OrderCommentsController < ApplicationController
  unloadable
  default_search_scope :orders
  model_object Order
  before_filter :find_model_object
  before_filter :find_project_from_association
  before_filter :authorize
  after_filter :send_notification, :only => :create

  def create
    raise Unauthorized unless User.current.allowed_to?(:comment_orders, @project)

    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @order.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to :controller => 'orders', :action => 'show', :id => @order
  end

  def destroy
    @order.comments.find(params[:comment_id]).destroy
    redirect_to :controller => 'orders', :action => 'show', :id => @order
  end

  private

  # ApplicationController's find_model_object sets it based on the controller
  # name so it needs to be overriden and set to @order instead
  def find_model_object
    super
    @order = @object
    @comment = nil
    @order
  end

  def send_notification
    if Setting.notified_events.include?('products_order_comment_added')
      ProductsMailer.order_comment_added(@comment).deliver
    end
  end

end
