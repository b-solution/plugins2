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

class MyControllerTest < ActionController::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :users, :projects, :roles, :members, :member_roles
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  def setup
    @request.session[:user_id] = 2
  end

  def test_account_without_edit_own_data
    with_people_settings 'edit_own_data' => '0' do
      post :account, { :user => { :firstname => 'newName', :language => 'ru'} }

      assert_redirected_to '/my/account'

      user = User.find(2)
      assert_not_equal 'newName', user.firstname
      assert_equal 'ru', user.language
    end
  end

  def test_account_with_edit_own_data
    with_people_settings 'edit_own_data' => '1' do
      post :account, { :user => { :firstname => 'newName', :language => 'ru'} }

      assert_redirected_to '/my/account'

      user = User.find(2)
      assert_equal 'newName', user.firstname
    end
  end

  def test_destroy_without_edit_own_data
    with_people_settings 'edit_own_data' => '0' do
      post :destroy

      assert_response :forbidden
      assert User.find(2).present?
    end
  end

end
