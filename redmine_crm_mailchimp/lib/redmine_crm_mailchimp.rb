Rails.configuration.to_prepare do
  require 'redmine_crm_mailchimp/patches/contacts_helper_patch'
  require 'redmine_crm_mailchimp/hooks/views_contacts_hook'
  require 'redmine_crm_mailchimp/hooks/view_layouts_hook'
end

module RedmineCrmMailchimp
  MAILCHIMP_URL = "https://admin.mailchimp.com"
  class Settings
    def initialize
      @settings = Setting.plugin_redmine_crm_mailchimp
      @assignments = @settings['mailchimp_query_assignments'] || []
      @query_ids = @assignments.map{ |x| x[:contact_query_id] }
      @queries = ContactQuery.eager_load(:project).where("#{ContactQuery.table_name}.id" => @query_ids)
    end

    def self.list_url(web_id)
      MAILCHIMP_URL + "/lists/members/?id=#{web_id}"
    end

    def self.[](key)
      Setting.plugin_redmine_crm_mailchimp[key.to_s]
    end

    def assignments
      @assignments.select do |assignment|
        visible_queries.any? { |query| query.id == assignment[:contact_query_id].to_i }
      end
    end

    def visible_queries
      @visible_queries ||= ( ContactQuery.eager_load(:project).visible + @queries ).uniq
    end

    def mailchimp_lists
      @mailchimp_lists ||= MailchimpList.all
    end

    def query_options
      visible_queries.map{ |x| [ x.name, x.id ] }
    end

    def mailchimp_options
      mailchimp_lists.map{ |x| [ x.name, x.id ] }
    end

    def has_queries?
      visible_queries.any?
    end
  end
end