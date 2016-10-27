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

class ProductCategory < ActiveRecord::Base
  unloadable

  attr_accessible :name, :parent_id, :code

  has_many :products, :dependent => :nullify, :foreign_key => "category_id"

  if Redmine::VERSION.to_s < '3.0'
    acts_as_nested_set :dependent => :destroy
  else
    include ProductCategoryNestedSet
  end

  validates_presence_of :name

  def allowed_parents
    @allowed_parents ||= ProductCategory.all - self_and_descendants
  end

  def to_s
    self.self_and_ancestors.map(&:name).join(' &#187; ').html_safe
  end

  def css_classes
    s = 'product_category'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  def self.category_tree(categories, &block)
    ancestors = []
    categories.sort_by(&:lft).each do |category|
      while (ancestors.any? && !category.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield category, ancestors.size
      ancestors << category
    end
  end

end
