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

class ProductsBundle < ActiveRecord::Base
  unloadable
  belongs_to :product
  belongs_to :bundle, :class_name => "Product"

  validate :validate_products_bundle

  private

  def validate_products_bundle
    if product && bundle
      errors.add :product_id, :invalid if bundle == product
      errors.add :base, :circular_dependency if bundle.all_dependent_issues.include? product
      errors.add :base, :circular_dependency if product.all_dependent_issues.include? bundle
    end
  end
end
