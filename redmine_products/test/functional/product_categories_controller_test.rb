# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class ProductCategoriesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :journals,
           :journal_details

  RedmineProducts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :product_categories])

  def setup
    User.current = nil
    @request.session[:user_id] = 1
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
    assert_select 'input[name=?]', 'product_category[name]'
  end

  def test_create
    assert_difference 'ProductCategory.count' do
      post :create, :product_category => {:name => 'New category', :parent_id => 1}
    end
    assert_redirected_to '/settings/plugin/redmine_products?tab=product_categories'
    category = ProductCategory.find_by_name('New category')
    assert_not_nil category
    assert_equal 1, category.parent_id
  end

  def test_create_failure
    post :create, :product_category => {:name => ''}
    assert_response :success
    assert_template 'new'
  end

  def test_edit
    get :edit, :id => 2
    assert_response :success
    assert_template 'edit'
    assert_select 'input[name=?][value=?]', 'product_category[name]', 'Root category 2'
  end

  def test_update
    assert_no_difference 'ProductCategory.count' do
      put :update, :id => 2, :product_category => { :name => 'Testing' }
    end
    assert_redirected_to '/settings/plugin/redmine_products?tab=product_categories'
    assert_equal 'Testing', ProductCategory.find(2).name
  end

  def test_update_failure
    put :update, :id => 2, :product_category => { :name => '' }
    assert_response :success
    assert_template 'edit'
  end

  def test_update_not_found
    put :update, :id => 97, :product_category => { :name => 'Testing' }
    assert_response 404
  end

  def test_destroy
    delete :destroy, :id => 2
    assert_redirected_to '/settings/plugin/redmine_products?tab=product_categories'
    assert_nil ProductCategory.where(:id => 2).first
  end
end
