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

class Person < User
  unloadable
  include Redmine::SafeAttributes

  self.inheritance_column = :_type_disabled

  has_one :information, :class_name => "PeopleInformation", :foreign_key => :user_id, :dependent => :destroy

  delegate :phone, :address, :skype, :birthday, :job_title, :company, :middlename, :gender, :twitter,
          :facebook, :linkedin, :department_id, :background, :appearance_date, :is_system, :manager_id,
          :to => :information, :allow_nil => true

  acts_as_customizable

  accepts_nested_attributes_for :information, :allow_destroy => true, :update_only => true, :reject_if => proc {|attributes| PeopleInformation.reject_information(attributes)}

  has_one :department, :through => :information

  has_one :manager, :through => :information

  rcrm_acts_as_taggable

  GENDERS = [[l(:label_people_male), 0], [l(:label_people_female), 1]]

  scope :in_department, lambda {|department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    eager_load(:information).where("(#{PeopleInformation.table_name}.department_id = ?) AND (#{Person.table_name}.type = 'User')", department_id)
  }
  scope :not_in_department, lambda {|department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    eager_load(:information).where("(#{PeopleInformation.table_name}.department_id != ?) OR (#{PeopleInformation.table_name}.department_id IS NULL)", department_id)
  }

  scope :seach_by_name, lambda {|search| eager_load(ActiveRecord::VERSION::MAJOR >= 4 ? [:information, :email_address] : [:information]).where("(LOWER(#{Person.table_name}.firstname) LIKE :search OR
                                                                    LOWER(#{Person.table_name}.lastname) LIKE :search OR
                                                                    LOWER(#{PeopleInformation.table_name}.middlename) LIKE :search OR
                                                                    LOWER(#{Person.table_name}.login) LIKE :search OR
                                                                    LOWER(#{(ActiveRecord::VERSION::MAJOR >= 4) ? (EmailAddress.table_name + '.address') : (Person.table_name + '.mail')}) LIKE :search)", {:search => search.downcase + "%"} )}

  scope :managers, lambda { joins("INNER JOIN #{PeopleInformation.table_name} ON #{Person.table_name}.id = #{PeopleInformation.table_name}.manager_id").uniq }

  safe_attributes 'custom_field_values',
                  'custom_fields',
                  'information_attributes',
  :if => lambda {|person, user| (person.new_record? && user.allowed_people_to?(:add_people, person)) || user.allowed_people_to?(:edit_people, person) }

  safe_attributes 'status',
    :if => lambda {|person, user| user.allowed_people_to?(:edit_people, person) && person.id != user.id && !person.admin }

  safe_attributes 'tag_list',
    :if => lambda {|person, user| user.allowed_people_to?(:manage_tags, person) }

  def type
    'User'
  end

  def email
    self.mail
  end

  def project
    nil
  end

  def subordinates
    scope = Person.eager_load(:information).where("#{PeopleInformation.table_name}.manager_id" => id.to_i)
    scope = scope.visible if Person.respond_to?(:visible)
    scope
  end

  def available_managers
    scope = Person.eager_load(:information).where("#{Person.table_name}.type" => 'User').logged
    scope = scope.visible if Person.respond_to?(:visible)

    if self.id.present?
      scope = scope.where("#{PeopleInformation.table_name}.manager_id != ? OR #{PeopleInformation.table_name}.manager_id IS NULL", id.to_i).where("#{Person.table_name}.id <> ?", id.to_i)
    end
    scope
  end

  def available_subordinates
    scope = Person.eager_load(:information).where("#{Person.table_name}.type" => 'User').logged
    scope = scope.visible if Person.respond_to?(:visible)

    if self.id.present?
      scope = scope.where("#{PeopleInformation.table_name}.manager_id != ? OR #{PeopleInformation.table_name}.manager_id IS NULL", id.to_i).where("#{Person.table_name}.id <> ?", id.to_i)
      scope = scope.where("#{Person.table_name}.id != ?", manager_id.to_i) if manager_id.present?
    end
    scope
  end

  def phones
    @phones || self.phone ? self.phone.split( /, */) : []
  end

  def next_birthday
    return if birthday.blank?
    year = Date.today.year
    mmdd = birthday.strftime('%m%d')
    year += 1 if mmdd < Date.today.strftime('%m%d')
    mmdd = '0301' if mmdd == '0229' && !Date.parse("#{year}0101").leap?
    return Date.parse("#{year}#{mmdd}")
  end

  def self.next_birthdays(limit = 10)
    Person.eager_load(:information).active.where("#{PeopleInformation.table_name}.birthday IS NOT NULL").sort_by(&:next_birthday).first(limit)
  end

  def self.tomorrow_birthdays
    Person.next_birthdays.select{|p| p.next_birthday == Date.today + 1 }
  end

  def self.today_birthdays
    Person.next_birthdays.select{|p| p.next_birthday == Date.today }
  end

  def self.week_birthdays
    Person.next_birthdays.select{|p| p.next_birthday <= Date.today.end_of_week &&
      p.next_birthday > Date.tomorrow }
  end

  def age
    return nil if birthday.blank?
    now = Time.now
    age = now.year - birthday.year - (birthday.to_time.change(:year => now.year) > now ? 1 : 0)
  end

  def editable_by?(usr, prj=nil)
    true
    # usr && (usr.allowed_to?(:edit_people, prj) || (self.author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def visible?(user=User.current)
    if Redmine::VERSION.to_s >= "3.0"
      principal = Principal.visible(user).where(:id => id).first
      return principal.present?
    end
    true
  end

  def attachments_visible?(user=User.current)
    true
  end

  def available_custom_fields
    CustomField.where("type = 'UserCustomField'").sorted.to_a
  end

  def remove_subordinate(subordinate_id)
    subordinate = Person.find(subordinate_id.to_i)
    return false if subordinate.blank?

    subordinate.safe_attributes = { 'information_attributes' => {'manager_id' => nil}}
    subordinate.save
  end

end
