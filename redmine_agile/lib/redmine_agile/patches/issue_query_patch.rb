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

require_dependency 'issue'

module RedmineAgile
  module Patches

    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :issues, :agile
          available_columns << QueryColumn.new(:story_points, :caption => :label_agile_story_points)
        end
      end

      module InstanceMethods
        def issues_with_agile(options={})
          issues = issues_without_agile(options)
          if RedmineAgile.issue_colors?
            Issue.load_agile_data(issues)
          end
          issues
        end
      end
    end

  end
end

unless IssueQuery.included_modules.include?(RedmineAgile::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineAgile::Patches::IssueQueryPatch)
end
