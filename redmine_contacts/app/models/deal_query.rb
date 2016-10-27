# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class DealQuery < CrmQuery
  include RedmineCrm::MoneyHelper

  self.queried_class = Deal

  self.available_columns = [
    QueryColumn.new(:name, :sortable => "#{Deal.table_name}.name", :caption => :field_deal_name),
    QueryColumn.new(:price, :sortable => ["#{Deal.table_name}.currency", "#{Deal.table_name}.price"], :default_order => 'desc', :caption => :field_price),
    QueryColumn.new(:status, :sortable => "#{Deal.table_name}.status_id", :groupable => true, :caption => :field_contact_status),
    QueryColumn.new(:currency, :sortable => "#{Deal.table_name}.currency", :groupable => true, :caption => :field_currency),
    QueryColumn.new(:contact, :sortable => lambda {Contact.fields_for_order_statement}, :groupable => true, :caption => :label_contact),
    QueryColumn.new(:category, :sortable => "#{Deal.table_name}.category_id", :groupable => true),
    QueryColumn.new(:probability, :sortable => "#{Deal.table_name}.probability", :groupable => "#{Deal.table_name}.probability", :caption => :label_crm_probability),
    QueryColumn.new(:expected_revenue, :sortable => ["#{Deal.table_name}.currency", "#{Deal.table_name}.price * (#{Deal.table_name}.probability / 100)"], :caption => :label_crm_expected_revenue),
    QueryColumn.new(:contact_city, :caption => :label_crm_contact_city, :groupable => "#{Address.table_name}.city", :sortable => "#{Address.table_name}.city"),
    QueryColumn.new(:contact_country, :caption => :label_crm_contact_country, :groupable => "#{Address.table_name}.country_code", :sortable => "#{Address.table_name}.country_code"),
    QueryColumn.new(:due_date, :sortable => "#{Deal.table_name}.due_date"),
    QueryColumn.new(:due_date, :sortable => "#{Deal.table_name}.due_date"),
    QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
    QueryColumn.new(:created_on, :sortable => "#{Deal.table_name}.created_on"),
    QueryColumn.new(:updated_on, :sortable => "#{Deal.table_name}.updated_on"),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => true),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("authors")}),
    QueryColumn.new(:background)
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
  end


  def initialize_available_filters
    add_available_filter "price", :type => :float, :label => :field_price
    add_available_filter "currency", :type => :list,
                                     :label => :field_currency,
                                     :values => collection_for_currencies_select(ContactsSetting.default_currency, ContactsSetting.major_currencies)
    add_available_filter "background", :type => :text, :label => :field_background
    add_available_filter "due_date", :type => :date, :order => 20
    add_available_filter "updated_on", :type => :date_past, :order => 20
    add_available_filter "created_on", :type => :date, :order => 21
    add_available_filter "probability", :type => :float, :label => :label_crm_probability

    deal_statuses = (project.blank? ? DealStatus.order("#{DealStatus.table_name}.status_type, #{DealStatus.table_name}.position") : project.deal_statuses) || []
    add_available_filter("status_id",
      :type => :list_status, :values => deal_statuses.map {|a| [a.name, a.id.to_s]}, :label => :field_contact_status, :order => 1
    ) unless deal_statuses.empty?

    initialize_project_filter
    initialize_author_filter
    initialize_assignee_filter
    initialize_contact_country_filter
    initialize_contact_city_filter

    add_custom_fields_filters(DealCustomField.where(:is_filter => true))
    add_associations_custom_fields_filters :contact, :notes, :author, :assigned_to
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += CustomField.where(:type => 'DealCustomField').all.map {|cf| QueryCustomFieldColumn.new(cf) }
    @available_columns += CustomField.where(:type => 'ContactCustomField').all.map {|cf| QueryAssociationCustomFieldColumn.new(:contact, cf) }
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:id, :name, :contact, :price]
  end

  def sql_for_status_id_field(field, operator, value)
    sql = ''
    case operator
    when "o"
      sql = "#{queried_table_name}.status_id IN (SELECT id FROM #{DealStatus.table_name} WHERE status_type = #{DealStatus::OPEN_STATUS})" if field == "status_id"
    when "c"
      sql = "#{queried_table_name}.status_id IN (SELECT id FROM #{DealStatus.table_name} WHERE status_type IN (#{DealStatus::WON_STATUS}, #{DealStatus::LOST_STATUS}))" if field == "status_id"
    else
      sql_for_field(field, operator, value, queried_table_name, field)
    end
  end

  def deal_amount
    @deal_amount ||= objects_scope.group("#{Deal.table_name}.currency").sum(:price)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def weighted_amount
    @weighted_amount ||= objects_scope.open.group("#{Deal.table_name}.currency").sum("#{Deal.table_name}.price * #{Deal.table_name}.probability / 100")
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def objects_scope(options={})
    scope = Deal.visible
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
    includes << :assigned_to if self.filters["assigned_to_id"] || (group_by_column && [:assigned_to].include?(group_by_column.name))
    includes
  end

end
