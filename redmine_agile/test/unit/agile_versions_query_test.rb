# encoding: utf-8
#
# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2016 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class AgileVersionsQueryTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issue_statuses,
           :issues,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries
  def filter_fields
    ['assigned_to_id', 'tracker_id', 'status_id', 'author_id', 'category_id'] # estimated_hours
  end

  def setup
    super
    RedmineAgile.create_issues
    @query = AgileVersionsQuery.new(:name => '_')
            @query.project = Project.find(2)
    @backlog_version = Version.find(7)
    @current_version = Version.find(5)
    User.current = User.find(1) #because issues selected according permissions
  end

  def test_backlog_version
    assert_equal @backlog_version, @query.backlog_version
  end

  def test_current_version
    assert_equal @current_version, @query.current_version
  end

  def test_backlog_issues
    assert_equal [100,101,102,103], @query.backlog_version_issues.map(&:id).sort
  end
  
  def test_current_issues
    assert_equal [104], @query.current_version_issues.map(&:id).sort
  end
  def test_current_version_issues
    assert_equal 1, @query.current_version_issues.count

    @query.build_from_params({ :f => ['status_id'], :o => ['status_id' => '*'], :v => ['status_id' => IssueStatus.all.map(&:id)]})
    assert_equal [104, 105, 106], @query.current_version_issues.map(&:id).sort
  end

  def test_filters_backlog_issues_in
    filter_fields.each do |filter|
      m = "Error in the #{filter} filter"
      hash = {
        :f =>[filter],
        :op => {filter => "="},
        :v => {filter => ['1','3']}}

      @query.build_from_params(hash)
      assert_equal [1,3], @query.backlog_version_issues.collect{ |issue| issue.send(filter.to_sym).to_i}.uniq.sort, m
    end
  end

  def test_filters_backlog_issues_not_in
    filter_fields.each do |filter|
      m = "Error in the #{filter} filter"
      hash = {
        :f =>[filter],
        :op => {filter => "!"},
        :v => {filter => ['1','3']}}

      @query.build_from_params(hash)
      issues = @query.backlog_version_issues.collect{ |issue| issue.send(filter.to_sym)}.uniq.sort
      assert_equal [], [1,3] & issues, m
    end
  end

  def test_with_few_filters
    hash = { 
        :f =>['assigned_to_id', 'priority_id', 'tracker_id', 'estimated_hours'],
        :op => {'assigned_to_id' => "*", 'priority_id' => '!', 'tracker_id' => '=', 'estimated_hours' => '><'},
        :v => {'priority_id' => ['3'], 'tracker_id' => ['1','2','3'], 'estimated_hours' => ['2','7']}}
    @query.build_from_params(hash)
    assert_equal [100], @query.backlog_version_issues.map(&:id)
    assert_equal [105], @query.current_version_issues.map(&:id).sort
  end

  def test_no_assigned_to
    hash = {
        :f =>['assigned_to_id'], :op => {'assigned_to_id' => "!*"}
    }
    @query.build_from_params(hash)
    assert_equal [104], @query.current_version_issues.map(&:id).sort
  end

  def test_no_version_issues
    hash = {
        :f =>['tracker_id'],
        :op => {'tracker_id' => '='},
        :v => {'tracker_id' => ['1','2','3']}}
    @query.build_from_params(hash)
    assert_equal [107,109], @query.no_version_issues({:q => 'bla'}).map(&:id).sort
    assert_equal [109], @query.no_version_issues({:q => '#109'}).map(&:id)
  end
end
