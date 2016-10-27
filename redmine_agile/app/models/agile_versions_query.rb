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


class AgileVersionsQuery < Query
  unloadable

  self.queried_class = Issue
  
  self.available_columns = [
    QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :groupable => true),
    QueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours"),
    QueryColumn.new(:priority, :sortable => "#{IssuePriority.table_name}.position", :default_order => 'desc', :groupable => true),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("users")}, :groupable => true),
    QueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name", :groupable => "#{Issue.table_name}.category_id"),
    QueryColumn.new(:status, :groupable => true, :caption => :field_invoice_status),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Issue.table_name}.assigned_to_id")  
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
  end

  def initialize_available_filters
    principals = []
    categories = []
    issue_custom_fields = []

    if project
      principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        principals += Principal.member_of(subprojects)
      end
      categories = project.issue_categories.all
      issue_custom_fields = project.all_issue_custom_fields
    else
      if all_projects.any?
        principals += Principal.member_of(all_projects)
      end
      issue_custom_fields = IssueCustomField.where(:is_for_all => true)
    end
    principals.uniq!
    principals.sort!
    users = principals.select {|p| p.is_a?(User)}

    add_available_filter "tracker_id",
      :type => :list, :values => trackers.collect{|s| [s.name, s.id.to_s] }
    add_available_filter "priority_id",
      :type => :list, :values => IssuePriority.all.collect{|s| [s.name, s.id.to_s] }

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("author_id",
      :type => :list, :values => author_values
    ) unless author_values.empty?

    assigned_to_values = []
    assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    assigned_to_values += (Setting.issue_group_assignment? ?
                              principals : users).collect{|s| [s.name, s.id.to_s] }
    add_available_filter("assigned_to_id",
      :type => :list_optional, :values => assigned_to_values
    ) unless assigned_to_values.empty?

    if categories.any?
      add_available_filter "category_id",
        :type => :list_optional,
        :values => categories.collect{|s| [s.name, s.id.to_s] }
    end

    add_available_filter "status_id",
      :type => :list_status, :values => IssueStatus.sorted.collect{|s| [s.name, s.id.to_s] }

    add_available_filter "estimated_hours", :type => :float
    add_custom_fields_filters(issue_custom_fields)

    add_associations_custom_fields_filters :project, :author, :assigned_to, :fixed_version
  end

  def backlog_version
    @backlog_version = project.shared_versions.open.where("LOWER(#{Version.table_name}.name) LIKE LOWER(?)", "backlog").first ||
        project.shared_versions.open.where(:effective_date => nil).first ||
        project.shared_versions.open.order("effective_date ASC").first
  end

  def backlog_version_issues
    return [] if backlog_version.blank?
    backlog_version.fixed_issues.visible.joins(query_includes).where(statement).sorted_by_rank
          end

  def current_version
    @current_version = Version.open.
        where(:project_id => project).
        where("#{Version.table_name}.id <> ?", self.backlog_version).
        order("effective_date DESC").first
  end

  def current_version_issues
    return [] if current_version.blank?
    current_version.fixed_issues.visible.joins(query_includes).where(statement).sorted_by_rank
          end

  def no_version_issues(params={})
    q = (params[:q] || params[:term]).to_s.strip
    scope = Issue.visible.joins(query_includes)
            if project
      project_ids = [project.id]
      project_ids += project.descendants.collect(&:id) if Setting.display_subprojects_issues?
      scope = scope.where(:project_id => project_ids)
    end
    scope = scope.where(statement).where(:fixed_version_id => nil).sorted_by_rank
            if q.present?
      if q.match(/^#?(\d+)\z/)
        scope = scope.where("(#{Issue.table_name}.id = ?) OR (LOWER(#{Issue.table_name}.subject) LIKE LOWER(?))", $1.to_i,"%#{q}%")
      else
        scope = scope.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{q}%")
      end
    end
    scope
  end

  def version_issues(version)
    version.fixed_issues.visible.joins(query_includes).where(statement).sorted_by_rank
          end
  private

  def query_includes
    [:project]
  end
end
