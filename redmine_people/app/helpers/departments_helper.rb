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

module DepartmentsHelper
  def department_tree(departments, &block)
    Department.department_tree(departments, &block)
  end

  def parent_department_select_tag(department)
    selected = department.parent if department
    # retrieve the requested parent department
    parent_id = (params[:department] && params[:department][:parent_id]) || params[:parent_id]
    if parent_id
      selected = (parent_id.blank? ? nil : Department.find(parent_id))
    end
    departments = department ? department.allowed_parents.compact : Department.all
    options = ''
    options << "<option value=''></option>"
    options << department_tree_options_for_select(departments, :selected => selected)
    content_tag('select', options.html_safe, :name => 'department[parent_id]', :id => 'department_parent_id')
  end

  def department_tree_options_for_select(departments, options = {})
    s = ''
    department_tree(departments) do |department, level|
      name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      tag_options = {:value => department.id}
      if department == options[:selected] || department.id == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(department))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag = options[:tag] || 'option'
      tag_options.merge!(yield(department)) if block_given?
      s << content_tag(tag, name_prefix + h(department), tag_options)
    end
    s.html_safe
  end

  def department_tree_links(departments, options = {})
    s = ''
    s << "<ul class='department-tree'>"
    s << "<li> #{link_to(l(:label_people_all), :set_filter => 1)} </li>"
    department_tree(departments) do |department, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      s << "<li>" + name_prefix + people_department_link(department , :class => "#{'selected' if @department && department == @department}")
      s << "</li>"
    end
    s << "</ul>"
    s.html_safe
  end

  def people_department_link(department, options={})
    p = {:controller => 'people',
     :action => 'index',
     :set_filter => 1,
     :fields => [:status, :department_id],
     :values => {:status => [Principal::STATUS_ACTIVE.to_s], :department_id => [department.id]},
     :operators => {:status => '=', :department_id => '='}}.merge(options)

    link_to department.name, p, options
  end

  def department_tabs
    [{:name => 'activity', :partial => 'activity', :label => l(:label_activity)},
     {:name => 'files', :partial => 'attachments', :label => l(:label_attachment_plural)}
    ]
  end

  def render_department_tabs(tabs)
    if tabs.any?
      render :partial => 'common/department_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

end
