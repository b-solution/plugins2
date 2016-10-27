namespace :redmine do
  namespace :mailchimp do
    desc 'Synchronizes all saved contact query to mailchimp lists assigned'
    task :sync_queries => :environment do
      RedmineCrmMailchimp::Settings.new.assignments.each do |assignment|
        @query = ContactQuery.find(assignment[:contact_query_id])
        @query_emails = @query.objects_scope.joins(:projects).where('email IS NOT NULL').where("email <> ''").pluck(:email).map(&:strip)
        @list = MailchimpList.find_by_id(assignment[:mailchimp_id])
        puts "Processing query #{@query.name} assigned to list #{@list.name}"
        @list_emails = @list.members
        @to_subscribe = @query_emails - @list_emails
        subscribed = @list.bulk_subscribe(@to_subscribe)['add_count']
        puts "Subscribed #{subscribed} new emails, unsubscribed #{unsubscribed}"
      end
    end
  end
end
