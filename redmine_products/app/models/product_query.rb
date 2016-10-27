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

class ProductQuery < CrmQuery
  include RedmineCrm::MoneyHelper
  include ProductsHelper

  self.queried_class = Product

  self.available_columns = [
    QueryColumn.new(:code, :sortable => "#{Product.table_name}.code", :caption => :label_products_code),
    QueryColumn.new(:name, :sortable => "#{Product.table_name}.name", :caption => :label_products_name),
    QueryColumn.new(:category, :sortable => "#{Product.table_name}.category_id", :groupable => true),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Product.table_name}.project_id"),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Product.table_name}.author_id"),
    QueryColumn.new(:price, :sortable => ["#{Product.table_name}.currency", "#{Product.table_name}.price"], :default_order => 'desc', :caption => :label_products_price),
    QueryColumn.new(:status, :sortable => "#{Product.table_name}.status_id", :groupable => "#{Product.table_name}.status_id", :caption => :label_products_status),
    QueryColumn.new(:currency, :sortable => "#{Product.table_name}.currency", :groupable => true, :caption => :field_invoice_currency),
    QueryColumn.new(:tags),
    QueryColumn.new(:created_at, :sortable => "#{Product.table_name}.created_at", :default_order => 'desc', :caption => :field_created_on),
    QueryColumn.new(:updated_at, :sortable => "#{Product.table_name}.updated_at", :default_order => 'desc', :caption => :field_updated_on),
    QueryColumn.new(:description, :sortable => "#{Product.table_name}.description")
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "=", :values => [Product::ACTIVE_PRODUCT.to_s]} }
  end


  def initialize_available_filters
    add_available_filter("status_id",
      :type => :list_status, :values => collection_product_statuses.map{|k, v| [k, v.to_s]}, :label => :label_products_status, :order => 0
    )

    add_available_filter "code", :type => :string, :label => :label_products_code
    add_available_filter "name", :type => :float, :label => :label_products_price
    add_available_filter "created_at", :type => :date_past, :label => :field_created_on
    add_available_filter "updated_at", :type => :date_past, :label => :field_updated_on

    initialize_project_filter
    initialize_author_filter

    add_available_filter "tags", :type => :list, :values => Product.available_tags(project.blank? ? {} : {:project => project.id}).collect{ |t| [t.name, t.name] }

    product_categories = []
    ProductCategory.category_tree(ProductCategory.order(:lft)) do |product_category, level|
      name_prefix = (level > 0 ? '-' * 2 * level + ' ' : '').html_safe #'&nbsp;'
      product_categories << [(name_prefix + product_category.name).html_safe, product_category.id.to_s]
    end
    add_available_filter("category_id", :type => :list, :label => :label_products_category,
      :values => product_categories
    ) if product_categories.any?
    add_custom_fields_filters(ProductCustomField.where(:is_filter => true))
    add_associations_custom_fields_filters :project
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += CustomField.where(:type => 'ProductCustomField').all.map {|cf| QueryCustomFieldColumn.new(cf) }
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:code, :name, :description, :price]
  end

  def sql_for_category_id_field(field, operator, value)
    category_ids = value
    category_ids += ProductCategory.where(:id => value).map(&:descendants).flatten.collect{|c| c.id.to_s}.uniq
    sql_for_field(field, operator, category_ids, Product.table_name, "category_id")
  end

  def sql_for_tags_field(field, operator, value)
    compare   = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    ids_list  = Product.tagged_with(value).collect{|product| product.id }.push(0).join(',')
    "( #{Product.table_name}.id #{compare} (#{ids_list}) ) "
  end

  def objects_scope(options={})
    scope = Product.visible
    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    scope = scope.includes((query_includes + (options[:include] || [])).uniq).
      where(statement).
      where(options[:conditions])
    scope
  end

  def query_includes
    includes = [:project]
    includes << :tags if self.filters["tags"]
    includes
  end

end
