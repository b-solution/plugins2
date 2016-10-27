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

class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :code, :unique => true, :null => false
      t.string :name, :null => false
      t.text :description
      t.integer :status_id, :default => Product::ACTIVE_PRODUCT, :null => false
      t.string :currency, :limit => 5
      t.decimal :price, :precision => 10, :scale => 2
      t.decimal :amount, :precision => 10, :scale => 2
      t.integer :author_id
      t.integer :project_id
      t.timestamps :null => false
    end
    add_index :products, [:code]
    add_index :products, [:author_id]
    add_index :products, [:status_id]
    add_index :products, [:project_id]
  end

end
