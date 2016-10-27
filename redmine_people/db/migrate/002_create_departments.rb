# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2016 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class CreateDepartments < ActiveRecord::Migration

  def change
    create_table :departments do |t|
      t.integer   :parent_id, :default => nil
      t.integer   :lft, :default => nil
      t.integer   :rgt, :default => nil
      t.string    :name
      t.text      :background
      t.integer   :head_id
      t.timestamps :null => false
    end
    add_index :departments, [:parent_id, :lft, :rgt]
    add_index :departments, :head_id
  end

end
