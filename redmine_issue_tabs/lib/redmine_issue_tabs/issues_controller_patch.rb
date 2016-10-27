module RedmineIssueTabs
  module IssuesControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_filter :get_time_entries, only: [:show]
      end
    end

    module InstanceMethods
      def get_time_entries
        @time_entries = @issue.time_entries.preload(:user, :activity).order("#{TimeEntry.table_name}.spent_on DESC")
        @time_entries_for_table = @issue.time_entries.preload(:user, :activity)
                                      .select('user_id, activity_id, sum(hours) as hours_sum')
                                      .group(:user_id, :activity_id).order(:activity_id)
      end
    end
  end
end
