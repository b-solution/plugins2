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

class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :number
      t.string :subject
      t.datetime :order_date
      t.datetime :closed_date
      t.string :currency
      t.integer :contact_id
      t.integer :status_id
      t.integer :assigned_to_id
      t.integer :author_id
      t.integer :project_id
      t.integer :comments_count
      t.text :description
      t.decimal :amount, :precision => 10, :scale => 2, :default => 0
      t.timestamps :null => false
    end
    add_index :orders, [:assigned_to_id]
    add_index :orders, [:author_id]
    add_index :orders, [:order_date]
    add_index :orders, [:project_id]
    add_index :orders, [:status_id]
    add_index :orders, [:contact_id]
  end
end
