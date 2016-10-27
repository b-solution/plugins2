# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class DealProcess < ActiveRecord::Base
  unloadable

  attr_accessible :deal, :author

  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :deal
  belongs_to :from, :class_name => "DealStatus", :foreign_key => "old_value"
  belongs_to :to, :class_name => "DealStatus", :foreign_key => "value"
  scope :visible, lambda {|*args| joins(:deal => :project).
                                  where(Project.allowed_to_condition(args.first || User.current, :view_deals)) }

  after_create :send_notification

  def recipients
    (deal.recipients + [self.author.mail]).uniq
  end

private
  def send_notification
    Mailer.crm_deal_updated(self).deliver if Setting.notified_events.include?('crm_deal_updated')
  end

end
