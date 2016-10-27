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

class ProductsIssuesController < ApplicationController
  unloadable

  before_filter :find_product, :only => [:destroy]
  before_filter :find_products, :only => :add
  before_filter :find_issue
  before_filter :authorize

  helper :products
  helper :issues

  def add
  end

  def new
  end

  def destroy
    @issue.products.delete(@product)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end


  def autocomplete_for_product
    @products = Product.visible.includes(:image).live_search(params[:q]).order("#{Product.table_name}.name").limit(100).all
    if @issue
      @products -= @issue.products
    end
    render :layout => false
  end

  private

  def find_products
    product_ids = params[:id] || (params[:products_issue] && params[:products_issue][:product_ids])
    @products = Product.find(product_ids)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    if params[:issue_id]
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif params[:project_id]
      @project = Project.visible.find_by_param(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end


end
