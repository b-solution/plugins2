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

class CreatePeopleInformation < ActiveRecord::Migration
  def self.up
    create_table :people_information , :id => false do |t|
      t.primary_key :user_id
      t.string :phone
      t.string :address
      t.string :skype
      t.date :birthday
      t.string :job_title
      t.string :company
      t.string :middlename
      t.integer :gender, :limit => 1
      t.string :twitter
      t.string :facebook
      t.string :linkedin
      t.text :background
      t.date :appearance_date
      t.integer :department_id
    end
  end

  def self.down
    drop_table :people_information
  end

end
