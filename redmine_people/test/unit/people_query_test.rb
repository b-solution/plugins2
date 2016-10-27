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

class PeopleQueryTest < ActiveSupport::TestCase
  include RedminePeople::TestCase::TestHelper

  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                            [:people_information, :departments, :custom_fields, :custom_values, :queries])

  def setup
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
   
    @query = PeopleQuery.new(:name => '_')
    @admin = Person.find(1)
    @person_2 = Person.find(2)
    @person_4 = Person.find(4)
 
    @queries = PeopleQuery.order('id').all

    User.current = @person_4
  end

  def test_visible_and_visible?
    assert_equal ['Private query 2', 'Public query 1'], PeopleQuery.visible(@admin).pluck(:name).sort
    assert_equal ['Private query 2', 'Private query 3', 'Public query 1'], PeopleQuery.visible(@person_4).pluck(:name).sort
    assert_equal ['Private query 2', 'Public query 1'], PeopleQuery.visible(@person_2).pluck(:name).sort

    assert @queries[0].visible?( @person_4 )
    assert @queries[1].visible?( @person_4 )
    assert @queries[2].visible?( @person_4 )

    assert @queries[0].visible?( @person_2 )
    assert (not @queries[2].visible?( @person_2 ))
  end

  def test_editable_by?
    assert @queries[1].editable_by?(@admin)
    assert @queries[1].editable_by?(@person_4)
    assert (not @queries[1].editable_by?(@person_2))

    PeopleAcl.create(@person_2.id, ['manage_public_people_queries'])

    assert @queries[1].editable_by?(@person_2)
  end
  def test_objects_scope
    # Without system account
    @query = @query.build_from_params({})
    assert_equal [1,2,3,4,8,9], @query.objects_scope.map(&:id).sort

    hash = {
      :f =>['address'],
      :op => {'address' => "="},
      :v => {'address' => ['WALL STREET']}}

    @query = @query.build_from_params(hash)
    assert_equal [2], @query.objects_scope.map(&:id)

    # with search param
    assert_equal [2], @query.objects_scope(:search => 'Ibn').map(&:id)
    assert (not @query.objects_scope(:search => 'Magomed').any?)
  end

  def test_object_scope_with_system_filter
    # Only system
    hash = {
      :f =>['is_system'],
      :op => {'is_system' => "="},
      :v => {'is_system' => [QUOTED_TRUE]}
    }

    @query = @query.build_from_params(hash)
    assert_equal [7], @query.objects_scope.map(&:id)

    # All accounts
    hash = {
      :f =>['is_system'],
      :op => {'is_system' => "="},
      :v => {'is_system' => [QUOTED_FALSE]}
    }

    @query = @query.build_from_params(hash)
    
    if Redmine::VERSION.to_s >= '3.0'
      # With visible scope
      assert_equal [1,2,3,4,7,8,9], @query.objects_scope.map(&:id).sort
    else
      assert_equal [1,2,3,4,5,7,8,9], @query.objects_scope.map(&:id).sort
    end
  end

  def test_objects_scope_with_custom_fields
    hash = {
      :f =>['cf_1', 'cf_2'],
      :op => {'cf_1' => "=", 'cf_2' => '>='},
      :v => {'cf_1' => ['Volvo'], 'cf_2' => ['180']}}

    @query = @query.build_from_params(hash)
    assert_equal [4], @query.objects_scope.map(&:id)
  end

  def test_object_scope_with_tag
    User.current = @admin
    @admin.safe_attributes = { 'tag_list' => 'Tag1'}
    @admin.save

    hash = {
      :f =>['tags'],
      :op => {'tags' => "="},
      :v => {'tags' => ['Tag1']}}

    @query = @query.build_from_params(hash)
    assert_equal [1], @query.objects_scope.map(&:id)
  end

  def test_object_count_by_group
    @query = @query.build_from_params(:group_by => 'job_title')
    assert_equal({ 'disigner' => 2, 'builder' => 1, 'architect' => 1, nil => 2 }, @query.object_count_by_group)

    @query = @query.build_from_params(:group_by => 'department_id')

    assert({ 2 => 3, 3 => 1, nil => 2 } == @query.object_count_by_group ||
            { '2' => 3, '3' => 1, nil => 2 } == @query.object_count_by_group)
  end

  def test_manager_filter
    p = lambda { |o, v| return {
        :f => ['manager_id'],
        :op => { 'manager_id' => o},
        :v => { 'manager_id' => [v] }
      }
    }
    @query = @query.build_from_params(p['=' , '3'])
    assert_equal [4], @query.objects_scope.map(&:id).sort

    @query = @query.build_from_params(p.call('!' , '3'))

    if Redmine::VERSION.to_s >= '3.0'
      # With visible scope
      assert_equal [1, 2, 3, 8, 9], @query.objects_scope.map(&:id).sort
    else
      assert_equal [1, 2, 3, 5, 8, 9], @query.objects_scope.map(&:id).sort
    end
  end

  def test_object_scope_with_department
    p = lambda { |v| return {
      :f =>['department_id'],
      :op => {'department_id' => "="},
      :v => {'department_id' => [v.to_s]}
      }
    }

    # With parent department
    @query = @query.build_from_params(p.call(1))
    assert_equal [4], @query.objects_scope.map(&:id)

    # With sub department
    @query = @query.build_from_params(p.call(3))
    assert_equal [4], @query.objects_scope.map(&:id)
  end

end
