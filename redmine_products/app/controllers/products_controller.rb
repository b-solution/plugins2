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

class ProductsController < ApplicationController
  unloadable

  before_filter :find_product_project, :only => [:create, :new]
  before_filter :find_product, :only => [:edit, :show, :destroy, :update, :add]
  before_filter :bulk_find_products, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_filter :authorize, :except => [:index, :edit, :update, :destroy]
  before_filter :find_optional_project, :only => [:index]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :attachments
  helper :custom_fields
  helper :timelog
  helper :sort
  helper :issues
  helper :context_menus
  helper :crm_queries
  helper :notes
  helper :queries
  include SortHelper
  include ProductsHelper
  include QueriesHelper
  include CrmQueriesHelper

  def index
    retrieve_crm_query('product')
    sort_init(@query.sort_criteria.empty? ? [['name', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end

      @products_count = @query.object_count
      @products_scope = @query.objects_scope
      @products_pages = Paginator.new @products_count, @limit, params['page']
      @offset ||= @products_pages.offset
      @product_count_by_group = @query.object_count_by_group
      @products = @query.results_scope(
        :search => params[:search],
        :include => [:author],
        :order => sort_clause,
        :limit  =>  @limit,
        :offset =>  @offset
      )

      respond_to do |format|
        format.html { render :partial => products_list_style, :layout => false if request.xhr? }
        format.api
        format.csv { send_data(query_to_csv(@products, @query, params), :type => 'text/csv; header=present', :filename => 'products.csv') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'products/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def add
    if params[:element].to_s.match(/order_lines_attributes_(.*)_product_id/)
      @element_id = $1
    end
  end

  def edit
  end

  def show
    @recent_orders = Order.by_project(@project).joins(:lines).where(:product_lines => {:product_id => @product}).visible.limit(5).order("#{Order.table_name}.order_date DESC")
  end

  def new
    @product = Product.new
    @product.currency = ContactsSetting.default_currency
  end

  def create
    @product = Product.new
    @product.safe_attributes = params[:product]
    @product.project = @project
    @product.author = User.current
    @product.save_attachments(params[:attachments] || (params[:product] && params[:product][:uploads]))
    if @product.save
      attach_image
      render_attachment_warning_if_needed(@product)

      flash[:notice] = l(:notice_successful_create)

      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @product }
        format.api  { render :action => 'show', :status => :created, :location => product_url(@product) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@product) }
      end
    end

  end

  def update
    @product.safe_attributes = params[:product]
    @product.save_attachments(params[:attachments] || (params[:product] && params[:product][:uploads]))
    if @product.save
      attach_image
      # attachments = Attachment.attach_files(@product, (params[:attachments] || (params[:product] && params[:product][:uploads])))
      render_attachment_warning_if_needed(@product)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @product  }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit"}
        format.api  { render_validation_errors(@product) }
      end
    end
  end

  def destroy
    if @product.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_delete)
    end
    respond_to do |format|
      format.html { redirect_to :action => "index", :project_id => @product.project }
      format.api  { head :ok }
    end

  end

  def context_menu
    @product = @products.first if (@products.size == 1)
    @can = {:edit =>  @products.collect{|c| c.editable_by?(User.current)}.inject{|memo,d| memo && d},
            :delete => @products.collect{|c| c.destroyable_by?(User.current)}.inject{|memo,d| memo && d}
            }

    # @back = back_url
    render :layout => false
  end

  def bulk_update
    unsaved_product_ids = []
    @products.each do |product|
      attributes = parse_params_for_bulk_product_attributes(params)
      product.safe_attributes = attributes
      unless product.save
        unsaved_product_ids << product.id
      end
    end
    set_flash_from_bulk_contact_save(@products, unsaved_product_ids)
    redirect_back_or_default({:controller => 'products', :action => 'index', :project_id => @project})

  end

  def bulk_destroy
    @products.each do |product|
      begin
        product.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => @project) }
      format.api  { head :ok }
    end
  end

  private

  def parse_params_for_bulk_product_attributes(params)
    attributes = (params[:product] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end

  def bulk_find_products
    @products = Product.includes(:project).where(:id => params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @products.empty?
    if @products.detect {|product| !product.visible?}
      deny_access
      return
    end
    @projects = @products.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_product_project
    project_id = params[:project_id] || (params[:product] && params[:product][:project_id])
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_product
    @product = Product.includes(:project).find(params[:id])
    @project ||= @product.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def attach_image
    if params[:product_image]
      params[:product_image][:description] = 'default_image'
      @product.image.destroy if @product.image
      Attachment.attach_files(@product, {"1" => params[:product_image]})
    end
  end

end
