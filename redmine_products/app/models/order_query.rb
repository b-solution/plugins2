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

class OrderQuery < CrmQuery

  self.queried_class = Order

  self.available_columns = [
    QueryColumn.new(:order_number, :sortable => "#{Order.table_name}.number", :caption => :label_products_number),
    QueryColumn.new(:order_subject, :sortable => "#{Order.table_name}.subject", :caption => :label_products_order_subject),
    QueryColumn.new(:products, :caption => :label_product_plural),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Order.table_name}.project_id"),
    QueryColumn.new(:contact, :sortable => "#{Contact.table_name}.last_name", :groupable => true, :caption => :label_contact),
    QueryColumn.new(:contact_city, :caption => :label_crm_contact_city, :groupable => "#{Address.table_name}.city", :sortable => "#{Address.table_name}.city"),
    QueryColumn.new(:contact_country, :caption => :label_crm_contact_country, :groupable => "#{Address.table_name}.country_code", :sortable => "#{Address.table_name}.country_code"),
    QueryColumn.new(:contact_email, :caption => :label_crm_contact_email, :sortable => "#{Contact.table_name}.email"),
    QueryColumn.new(:order_date, :sortable => "#{Order.table_name}.order_date", :default_order => 'desc', :caption => :label_products_order_date),
    QueryColumn.new(:order_amount, :sortable => ["#{Order.table_name}.currency", "#{Order.table_name}.amount"], :default_order => 'desc', :caption => :label_products_amount),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Order.table_name}.author_id"),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Order.table_name}.assigned_to_id"),
    QueryColumn.new(:status, :sortable => "#{OrderStatus.table_name}.position", :groupable => "#{Order.table_name}.status_id", :caption => :label_products_status),
    QueryColumn.new(:created_at, :sortable => "#{Order.table_name}.created_at", :default_order => 'desc', :caption => :field_created_on),
    QueryColumn.new(:updated_at, :sortable => "#{Order.table_name}.updated_at", :default_order => 'desc', :caption => :field_updated_on),
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
  end


  def initialize_available_filters
    order_statuses = OrderStatus.order(:position)
    add_available_filter("status_id",
      :type => :list_status,
      :values => order_statuses.map {|a| [a.name, a.id.to_s]},
      :label => :label_products_status
    ) unless order_statuses.empty?

    add_available_filter "number", :type => :string, :label => :label_products_number
    add_available_filter "subject", :type => :text, :label => :label_products_order_subject
    add_available_filter "amount", :type => :float, :label => :label_products_amount
    add_available_filter "created_at", :type => :date_past, :label => :field_created_on
    add_available_filter "updated_at", :type => :date_past, :label => :field_updated_on
    add_available_filter "closed_date", :type => :date_past, :label => :label_products_closed_date
    add_available_filter "order_date", :type => :date, :label => :label_products_order_date

    initialize_project_filter
    initialize_author_filter
    initialize_assignee_filter
    initialize_contact_country_filter
    initialize_contact_city_filter

    products = Product.visible.all
    add_available_filter("products",
      :type => :list_optional, :values => products.map {|a| [a.name, a.id.to_s]}, :label => :label_product_plural
    ) unless products.empty?

    product_categories = []
    ProductCategory.category_tree(ProductCategory.order(:lft)) do |product_category, level|
      name_prefix = (level > 0 ? '-' * 2 * level + ' ' : '').html_safe #'&nbsp;'
      product_categories << [(name_prefix + product_category.name).html_safe, product_category.id.to_s]
    end
    add_available_filter("product_category_id", :type => :list, :label => :label_products_category_filter,
      :values => product_categories
    ) if product_categories.any?
    add_custom_fields_filters(OrderCustomField.where(:is_filter => true))
    add_associations_custom_fields_filters :project, :contact, :products, :lines
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += CustomField.where(:type => 'OrderCustomField').all.map {|cf| QueryCustomFieldColumn.new(cf) }
    @available_columns += CustomField.where(:type => 'ContactCustomField').all.map {|cf| QueryAssociationCustomFieldColumn.new(:contact, cf) }
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:order_number, :order_date, :order_amount, :contact]
  end

  def sql_for_order_subject_field(field, operator, value)
     sql_for_field(field, operator, value, Order.table_name, "subject")
  end

  def sql_for_order_number_field(field, operator, value)
     sql_for_field(field, operator, value, Order.table_name, "number")
  end

  def sql_for_order_amount_field(field, operator, value)
     sql_for_field(field, operator, value, Order.table_name, "amount")
  end

  def sql_for_products_field(field, operator, value)
    if operator == '*' # Any group
      products = Product.visible.all
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      products = Product.visible.all
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      products = Product.visible.where(:id => value)
    end
    products ||= []

    order_products = products.map(&:id).uniq.compact.sort.collect(&:to_s)

    '(' + sql_for_field("product_id", operator, order_products, ProductLine.table_name, "product_id", false) + ')'
  end

  def sql_for_product_category_id_field(field, operator, value)
    category_ids = value
    category_ids += ProductCategory.where(:id => value).map(&:descendants).flatten.collect{|c| c.id.to_s}.uniq
    sql_for_field(field, operator, category_ids, Product.table_name, "category_id")
  end

  def sql_for_status_id_field(field, operator, value)
    sql = ''
    case operator
    when "o"
      sql = "#{queried_table_name}.status_id IN (SELECT id FROM #{OrderStatus.table_name} WHERE is_closed=#{ActiveRecord::Base.connection.quoted_false})" if field == "status_id"
    when "c"
      sql = "#{queried_table_name}.status_id IN (SELECT id FROM #{OrderStatus.table_name} WHERE is_closed=#{ActiveRecord::Base.connection.quoted_true})" if field == "status_id"
    else
      sql_for_field(field, operator, value, queried_table_name, field)
    end
  end

  def order_amount
    objects_scope.group("#{Order.table_name}.currency").sum(:amount)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def objects_scope(options={})
    scope = Order.visible
    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    scope = scope.includes((query_includes + (options[:include] || [])).uniq).
      where(statement).
      where(options[:conditions])
    scope
  end

  def query_includes
    includes = [:status, :project]
    includes << {:contact => :address} if self.filters["contact_country"] ||
        self.filters["contact_city"] ||
        [:contact_country, :contact_city].include?(group_by_column.try(:name))
    includes << :products if self.filters["products"]
    includes << :products if self.filters["product_category_id"]
    includes << group_by_column.try(:name) if group_by_column && ![:contact_country, :contact_city].include?(group_by_column.name)
    includes
  end

end
