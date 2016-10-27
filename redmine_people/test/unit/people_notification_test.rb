# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class PeopleNotificationTest < ActiveSupport::TestCase
  fixtures :people_notifications

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                            [:people_notifications])

  def test_once_notifications
    today_notifications = PeopleNotification.today(people_notifications(:people_notification_001).start_date)
    assert today_notifications.include?(people_notifications(:people_notification_002))
    # and all created in this date
    assert today_notifications.include?(people_notifications(:people_notification_001))
    assert today_notifications.include?(people_notifications(:people_notification_003))
    assert today_notifications.include?(people_notifications(:people_notification_004))
  end


  def test_every_day_notifications
    today_notifications = PeopleNotification.today(people_notifications(:people_notification_001).start_date + 1.day)
    assert today_notifications.include?(people_notifications(:people_notification_001))
    assert !today_notifications.include?(people_notifications(:people_notification_003))
    assert !today_notifications.include?(people_notifications(:people_notification_004))
  end

  def test_every_week_notifications
    today_notifications = PeopleNotification.today(people_notifications(:people_notification_003).start_date + 1.week)
    assert today_notifications.include?(people_notifications(:people_notification_003))
    assert today_notifications.include?(people_notifications(:people_notification_001))
  end

  def test_every_month_notifications
    today_notifications = PeopleNotification.today(people_notifications(:people_notification_004).start_date + 1.month)
    assert today_notifications.include?(people_notifications(:people_notification_004))
    assert today_notifications.include?(people_notifications(:people_notification_001))
    assert !today_notifications.include?(people_notifications(:people_notification_005)) #because 005 end date less then today
  end


end
