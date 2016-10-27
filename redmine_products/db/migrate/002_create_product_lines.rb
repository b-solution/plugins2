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

class CreateProductLines < ActiveRecord::Migration
  def change
    create_table :product_lines do |t|
      t.references :container, :polymorphic => true
      t.integer :product_id
      t.text :description
      t.decimal :quantity, :precision => 10, :scale => 2, :default => 0
      t.decimal :tax, :precision => 6, :scale => 4
      t.decimal :discount, :precision => 6, :scale => 4
      t.decimal :price, :precision => 10, :scale => 2, :default => 0
      t.integer :position
    end
    add_index :product_lines, [:product_id]
    add_index :product_lines, [:container_id, :container_type]
    add_index :product_lines, [:position]
  end
end
