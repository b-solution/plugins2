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

require_dependency 'queries_helper'

module RedminePeople
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :column_value, :people
        end
      end


      module InstanceMethods
        def column_value_with_people(column, list_object, value)
          if column.name == :id && list_object.is_a?(Person)
            link_to value, person_path(value)
          elsif column.name == :gender && list_object.is_a?(Person)
            if value == 1
              l(:label_people_female)
            else
              l(:label_people_male)
            end
          elsif column.name == :manager_id && list_object.is_a?(Person)
            list_object.manager.try(:name)
          elsif column.name == :name && list_object.is_a?(Person)
            person_tag(list_object)
          elsif column.name == :status && list_object.is_a?(Person)
            case value
            when Principal::STATUS_ACTIVE
              l(:status_active)
            when Principal::STATUS_REGISTERED
              l(:status_registered)
            when Principal::STATUS_LOCKED
              l(:status_locked)
            else
              value
            end
          elsif column.name == :department_id && list_object.is_a?(Person)
            department_tree_tag(list_object)
          elsif column.name == :tags && list_object.is_a?(Person)
            person_tags = []
            value.each do |tag|
              person_tags << tag.name
            end
            person_tags.join(", ")         
          else
            column_value_without_people(column, list_object, value)
          end
        end

      end

    end
  end
end

unless QueriesHelper.included_modules.include?(RedminePeople::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedminePeople::Patches::QueriesHelperPatch)
end
