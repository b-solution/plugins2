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

class ProductLine < ActiveRecord::Base
  unloadable
  attr_accessible :product_id, :description, :quantity, :price, :tax, :discount, :position, :custom_field_values

  belongs_to  :product
  belongs_to  :container, :polymorphic => true

  validates_presence_of :container
  validates_presence_of :description, :if => Proc.new { |line| line.product.blank? }
  validates_numericality_of :price, :quantity, :tax, :discount, :allow_nil => true
  validates_numericality_of :tax, :discount, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100

  acts_as_list :scope => :container
  acts_as_customizable
  acts_as_priceable :price, :total

  def total
  	self.price.to_f * self.quantity.to_f * (1 - discount.to_f/100)
  end

  def tax_to_s
    tax ? "#{"%.2f" % tax.to_f}%": ""
  end

  def discount_to_s
    discount ? "#{"%.2f" % discount.to_f}%": ""
  end

  def currency
  	self.container.currency if self.container.respond_to?(:currency)
  end

  def tax_amount
    ContactsSetting.tax_exclusive? ? self.tax_exclusive : self.tax_inclusive
  end

  def tax_inclusive
    total - (total/(1+tax.to_f/100))
  end

  def tax_exclusive
    total * tax.to_f/100
  end

  def full_description
    "#{product.name + ' - ' if product}#{description}"
  end

private


end
