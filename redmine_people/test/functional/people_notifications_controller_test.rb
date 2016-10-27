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

class PeopleNotificationsControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :roles, :members, :member_roles
  fixtures :people_notifications, :people_information

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                            [:people_notifications, :people_information])
  def setup
    @request.session[:user_id] = 2
    Setting.plugin_redmine_people["visibility"] = 1
    PeopleAcl.create(2, [ "view_people", "edit_notification"])
  end

  def test_new
    with_people_settings 'use_notifications' => '1' do
      get :new
      assert_response :success
      assert_template :new
      assert_select 'textarea.wiki-edit'
    end
  end

  def test_create
    with_people_settings 'use_notifications' => '1' do
      assert_difference 'PeopleNotification.count' do
        post :create, :people_notification => { :description => 'desc', :frequency => 'once',
          :start_date => Date.today, :end_date => Date.today + 1.year, :active => true, :kind => 'notice'}
      end
    end
  end

  def test_update
    with_people_settings 'use_notifications' => '1' do
      notif = people_notifications(:people_notification_001)
      post :update, :id => notif.id, :people_notification => 'New desc'
      notif.reload
      assert 'New desc', notif.description
    end
  end

  def test_destory
    with_people_settings 'use_notifications' => '1' do
      assert_difference 'PeopleNotification.count', -1 do
        post :destroy, :id => people_notifications(:people_notification_001).id
      end
    end
  end

  def test_new_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_notifications' => '1' do
      get :new
      assert_response 403
    end
  end

  def test_index_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_notifications' => '1', 'visibility' => '0' do
      get :index
      assert_response 403
    end
  end

  def test_create_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_notifications' => '1' do
      post :create
      assert_response 403
    end
  end

  def test_update_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_notifications' => '1' do
      post :update, :id => people_notifications(:people_notification_001).id
      assert_response 403
    end
  end

  def test_destory_without_permissions
    @request.session[:user_id] = 3
    with_people_settings 'use_notifications' => '1' do
      assert_difference 'PeopleNotification.count', 0 do
        post :destroy, :id => people_notifications(:people_notification_001).id
      end
    end
  end

  def test_preview
    with_people_settings 'use_notifications' => '1' do
      post :preview, :people_notification => { :description => 'desc', :frequency => 'once',
          :start_date => Date.today, :end_date => Date.today + 1.year, :active => true,
          :kind => 'notice'}
      assert_response :success
      assert_select '.wiki', :text => 'desc'
    end
  end

  def test_active
    with_people_settings 'use_notifications' => '1' do
      today_notifs = PeopleNotification.today.count
      get :active
      assert_response :success
      assert_select '.wiki', :count => today_notifs #show all active notification for today
      assert_equal Date.today, @request.session[:notifications_date]
    end
  end

  def test_active_when_no_active_nofitications
    with_people_settings 'use_notifications' => '1' do
      PeopleNotification.where(:active => true).update_all(:active => false)
      get :active
      assert @response.body.blank?
    end
  end

  def test_active_when_off_setting
    with_people_settings 'use_notifications' => '0' do
      get :active
      assert_response :redirect
    end
  end

  def test_second_call_active
    with_people_settings 'use_notifications' => '1' do
      @request.session[:notifications_date] = Date.today
      get :active
      assert @response.body.blank?
    end
  end

  def test_change_saved_notification
    with_people_settings 'use_notifications' => '1' do
      get :active
      notif = people_notifications(:people_notification_001)
      notif.description = 'changed description'
      notif.save
      get :active
      assert_select '.wiki', :text => 'changed description'
    end
  end

  def test_add_new_today_people_notification_after_first_show
    with_people_settings 'use_notifications' => '1' do
      get :active
      notif = PeopleNotification.create(:description => 'new notification', :end_date => Date.today,
        :kind => 'error', :frequency => 'once', :active => true)
      get :active
      assert_select '.wiki', :text => notif.description
    end
  end

  def test_people_notification_with_future_date
    with_people_settings 'use_notifications' => '1' do
      get :active
      notif = PeopleNotification.create(:description => 'new notification', :end_date => Date.today,
        :kind => 'error', :frequency => 'once', :active => true,
        :start_date => Date.today + 1.day)
      get :active
      assert @response.body.blank?
    end
  end

  def test_show_birthdays_with_ages
    person = Person.find(1)
    person.information.birthday = (Date.today + (Date.today.leap? ? 1 : 0) ) - 33.years
    person.save
    with_people_settings 'use_notifications' => '1', 'visibility' => '1', 'hide_age' => '0', 'show_birthday_notifications' => '1'  do
      get :active
      assert_select '.birthdays'
      assert_select '.contacts_header', "#{person.name} (33)"
    end
  end

  def test_show_birthdays_without_ages
    person = Person.find(1)
    person.information.birthday = (Date.today + (Date.today.leap? ? 1 : 0) ) - 33.years
    person.save
    with_people_settings 'use_notifications' => '1', 'visibility' => '1', 'hide_age' => '1' , 'show_birthday_notifications' => '1' do
      get :active
      assert_select '.birthdays'
      assert_select '.contacts_header', "#{person.name}"
    end
  end

  def test_show_birthdays_no_permission
    person = Person.find(1)
    person.information.birthday = Date.today - 33.years
    person.save
    @request.session[:user_id] = 3
    with_people_settings 'use_notifications' => '1' do
      get :active
      assert_select '.birthdays', :count => 0
    end
  end
end
