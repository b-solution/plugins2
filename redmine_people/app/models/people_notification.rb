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

class PeopleNotification < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable

  FREQUENCY = %w(once everyday wday mday)
  KIND = %w(notice warning error)
  STATUS = %w(all active)

  acts_as_attachable

  validates_presence_of :description, :end_date

  scope :active, lambda { where('active = ? AND end_date >= ?', true, Date.today) }

  before_save :set_start_date

  attr_protected :id
  safe_attributes 'description',
    'start_date',
    'end_date',
    'frequency',
    'kind',
    'active'

  def self.for_status(status)
    status = !status.blank? && self::STATUS.include?(status) ? status : 'active'
    self.send(status)
  end

  def project
    nil
  end

  def attachments_visible?(user=User.current)
    true
  end

  def start_date
    return created_at.to_date if  !self[:start_date] && !created_at.nil?
    self[:start_date]
  end

  def css_class
    "flash #{kind}" if kind
  end

  def self.today(today=Date.today)
    notifications = self.active.where("(frequency = 'once' AND start_date = ?) OR (frequency = 'everyday')", today)
    notifications += self.active.where(:frequency => 'wday').reject{|m|  m.start_date.wday != today.wday}
    notifications += self.active.where(:frequency => 'mday').reject{|m|  m.start_date.mday != today.mday}
  end

  private

  def set_start_date
    self.start_date = Date.today unless start_date
  end
end
