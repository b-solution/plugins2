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

require File.expand_path('../../../test_helper', __FILE__)

class CrmFetcherTest < ActiveSupport::TestCase

  fixtures :users, :projects, :roles, :members, :member_roles,
           :enabled_modules, :issues, :issue_statuses, :trackers, :attachments

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '../test/fixtures/',
                            [:people_information, :departments])

  
  def events(user = User.current, author = nil, date1 = nil, date2 = nil, limit = 5)
    Redmine::Activity::CrmFetcher.new(user, :author => author).events(date1, date2, :limit => limit)
  end

  def test_events
    assert_equal [2, 3], events(User.current , User.all).map{ |e| e.author.id }.uniq.sort

    assert_equal [User.find(3)], events(User.current , User.find(3)).map(&:author)
  end

end
