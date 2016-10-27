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

class ProductCategoriesController < ApplicationController
  unloadable

  layout 'admin'

  before_filter :require_admin, :except => [:index, :show]
  before_filter :find_category, :only => [:update, :edit, :destroy, :show]
  accept_api_auth :index, :create, :destroy, :update, :show

  def index
    scope = ProductCategory.order(:lft)
    scope = scope.where(:code => params[:code]) if params[:code]
    @categories = scope
    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end


  def new
    @category = ProductCategory.new
  end

  def create
    @category = ProductCategory.new(params[:product_category])

    if @category.save
      flash[:notice] = l(:notice_successful_create)

      respond_to do |format|
        format.html { redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'product_categories' }
        format.api  { render :action => 'show', :status => :created, :location => product_category_url(@category) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@category) }
      end
    end

  end

  def edit
  end

  def update
    if @category.update_attributes(params[:product_category])
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'product_categories' }
        format.api  { render :action => 'show', :status => :created, :location => product_category_url(@category) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@category) }
      end
    end
  end

  def destroy
    @category.destroy
  ensure
    redirect_to :action =>"plugin", :id => "redmine_products", :controller => "settings", :tab => 'product_categories'
  end

  private

  def find_category
    @category = ProductCategory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
