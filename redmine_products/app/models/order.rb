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

class Order < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  alias_attribute :order_number, :number
  alias_attribute :order_subject, :subject
  alias_attribute :order_amount, :amount
  alias_attribute :created_on, :created_at

  belongs_to :project
  belongs_to :status, :class_name => "OrderStatus", :foreign_key => 'status_id'
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :contact

  has_many :lines, :class_name => "ProductLine", :as => :container, :order => "position", :dependent => :delete_all
  has_many :products, :through => :lines, :uniq => true
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"

  scope :by_project, lambda {|project_id| where(:project_id => project_id) unless project_id.blank? }
  scope :visible, lambda {|*args| joins(:project).where(Project.allowed_to_condition(args.first || User.current, :view_orders)) }
  scope :open, lambda {|*args|
    is_closed = args.size > 0 ? !args.first : false
    includes(:status).where("#{OrderStatus.table_name}.is_closed = ?", is_closed)
  }
  scope :live_search, lambda {|search| where("(LOWER(#{Order.table_name}.number) LIKE ? OR
                                                LOWER(#{Order.table_name}.subject) LIKE ? OR
                                                LOWER(#{Order.table_name}.description) LIKE ?)",
                                                                 "%" + search.downcase + "%",
                                                                 "%" + search.downcase + "%",
                                                                 "%" + search.downcase + "%") }

  acts_as_event :datetime => :created_at,
                :url => Proc.new {|o| {:controller => 'orders', :action => 'show', :id => o}},
                :type => 'icon-order',
                :title => Proc.new {|o| "#{l(:label_products_order_placed)} ##{o.number} (#{o.status_id}): #{o.amount_to_s}" },
                :description => Proc.new {|o| [o.number, o.contact ? o.contact.name : '', o.amount_to_s, o.description].join(' ') }

  if ActiveRecord::VERSION::MAJOR >= 4
    acts_as_activity_provider :type => 'orders',
                              :permission => :view_orders,
                              :timestamp => "#{table_name}.created_at",
                              :author_key => :author_id,
                              :scope => joins(:project)

    acts_as_searchable :columns => ["#{table_name}.number"],
                       :project_key => "#{Project.table_name}.id",
                       :scope => includes([:project]),
                       :permission => :view_orders,
                       :date_column => "created_at"
  else
    acts_as_activity_provider :type => 'orders',
                              :permission => :view_orders,
                              :timestamp => "#{table_name}.created_at",
                              :author_key => :author_id,
                              :find_options => {:include => :project}

    acts_as_searchable :columns => ["#{table_name}.number"],
                       :date_column => "#{table_name}.created_at",
                       :include => [:project],
                       :project_key => "#{Project.table_name}.id",
                       :permission => :view_orders,
                       # sort by id so that limited eager loading doesn't break with postgresql
                       :order_column => "#{table_name}.number"
  end

  acts_as_customizable
  acts_as_watchable
  acts_as_attachable
  acts_as_priceable :amount, :tax_amount, :subtotal, :total

  before_save :calculate_amount, :update_closed_date
  before_validation :assign_lines

  after_create :send_mail_about_create
  after_update :send_mail_about_update

  validates_presence_of :number, :order_date, :project, :status_id
  validates_uniqueness_of :number

  accepts_nested_attributes_for :lines, :allow_destroy => true

  safe_attributes 'number',
    'subject',
    'order_date',
    'currency',
    'contact_id',
    'status_id',
    'assigned_to_id',
    'project_id',
    'description',
    'custom_field_values',
    'custom_fields',
    'lines_attributes',
    :if => lambda {|order, user| order.new_record? || user.allowed_to?(:edit_orders, order.project) }

  def initialize(attributes = nil, *args)
    super
    if new_record?
      # set default values for new records only
      self.status_id ||= OrderStatus.default.try(:id)
    end
  end

  def visible?(usr = nil)
    (usr || User.current).allowed_to?(:view_orders, self.project)
  end

  def editable_by?(usr, prj = nil)
    prj ||= self.project
    usr && (usr.allowed_to?(:edit_orders, prj))
  end

  def destroyable_by?(usr, prj = nil)
    prj ||= self.project
    usr && (usr.allowed_to?(:delete_orders, prj))
  end

  def commentable?(user = User.current)
    user.allowed_to?(:comment_orders, project)
  end

  def self.allowed_target_projects(user = User.current)
    Project.where(Project.allowed_to_condition(user, :edit_orders))
  end

  def is_closed?
    self.status && self.status.is_closed?
  end

  def invoices
    @invoices ||= Invoice.where(:order_number => self.order_number) if ProductsSettings.invoices_plugin_installed?
  end

  def recipients
    notified = []
    if assigned_to
      notified += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
    end
    notified = notified.select {|u| u.active?}

    notified += project.notified_users
    notified.uniq!
    # Remove users that can not view the order
    notified.reject! {|user| !visible?(user)}
    notified.collect(&:mail)
  end

  def status_was
    if status_id_changed? && status_id_was.present?
      @status_was ||= OrderStatus.where(:id => status_id_was).first
    end
  end

  def contact_country
    self.try(:contact).try(:address).try(:country)
  end

  def contact_email
    self.try(:contact).try(:primary_email)
  end

  def contact_city
    self.try(:contact).try(:address).try(:city)
  end

  def update_closed_date
    if closing? || (new_record? && is_closed?)
      self.closed_date = updated_at
    elsif !self.closed_date.blank?
      self.closed_date = nil
    end
  end

  def closing?
    if !new_record? && status_id_changed?
      if status_was && status && !status_was.is_closed? && status.is_closed?
        return true
      end
    end
    false
  end

  def has_taxes?
    !self.lines.map(&:tax).all?{|t| t == 0 || t.blank?}
  end

  def has_discounts?
    !self.lines.map(&:discount).all?{|t| t == 0 || t.blank?}
  end

  def tax_amount
    self.lines.select{|l| !l.marked_for_destruction?}.inject(0){|sum,l| sum + l.tax_amount }.to_f
  end

  def subtotal
    self.lines.select{|l| !l.marked_for_destruction?}.inject(0){|sum,l| sum + l.total}.to_f
  end

  def total_units
    self.lines.inject(0){|sum,l| sum + (l.product.blank? ? 0 : l.quantity)}
  end

  def calculate_amount
    @order_amount_was = self.amount
    self.amount = self.subtotal + (ContactsSetting.tax_exclusive? ? self.tax_amount : 0)
  end
  alias_method :calculate, :calculate_amount

  def order_amount_was
    @order_amount_was
  end

private

  def assign_lines
    if new_record?
      self.lines.each{|l| l.container = self}
    end
  end

  def send_mail_about_create
    ProductsMailer.order_added(self).deliver if Setting.notified_events.include?('products_order_added')
  end

  def send_mail_about_update
    ProductsMailer.order_updated(self).deliver if (status_id_changed? || amount_changed?) &&
                                                  Setting.notified_events.include?('products_order_updated')
  end


end
