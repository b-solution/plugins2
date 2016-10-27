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

class ProductsMailer < Mailer
  helper :products

  def order_added(order)
    @order = order.reload
    redmine_headers 'Project' => @order.project.identifier,
                    'Order-Number' => @order.number,
                    'Order-Id' => @order.id
    redmine_headers 'Order-Assignee' => @order.assigned_to.login if @order.assigned_to
    message_id order
    references @order
    @author = User.current
    recipients = @order.recipients
    # Watchers in cc
    cc = @order.watcher_recipients - recipients
    s = "[#{@order.project.name} - #{l(:label_order)} ##{@order.number}] (#{@order.status.name if @order.status}) #{@order.amount_to_s}"
    mail :to => recipients,
         :cc => cc,
         :subject => s
  end

  def order_updated(order)
    @status_was = order.status_was if order.status_id_changed? && order.status_id_was.present?
    @order_amount_was = order.order_amount_was unless order.order_amount_was == order.amount
    @order = order.reload
    redmine_headers 'Project' => @order.project.identifier,
                    'Order-Number' => @order.number,
                    'Order-Id' => @order.id
    redmine_headers 'Order-Assignee' => @order.assigned_to.login if @order.assigned_to
    message_id order
    references @order
    @author = User.current
    recipients = @order.recipients
    # Watchers in cc
    cc = @order.watcher_recipients - recipients
    s = "[#{@order.project.name} - #{l(:label_order)} ##{@order.number}] (#{@order.status.name if @order.status}) #{@order.amount_to_s}"
    mail :to => recipients,
         :cc => cc,
         :subject => s
  end

  def order_comment_added(comment)
    order = comment.commented
    redmine_headers 'Project' => order.project.identifier
    @author = comment.author
    message_id comment
    @order = order
    @comment = comment
    mail :to => order.recipients,
     :cc => order.watcher_recipients,
     :subject => "Re: [#{order.project.name}] #{l(:label_order)}: ##{order.number}"
  end

end
