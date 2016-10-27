class MailchimpApi
  include Singleton

  def current
    Excon.defaults[:read_timeout] = 180
    Excon.defaults[:ssl_verify_peer] = false
    api_key = Setting.plugin_redmine_crm_mailchimp[:api_key]
    return nil if api_key.blank?
    if @mailchimp_api.nil? || @mailchimp_api.apikey != api_key
      @mailchimp_api = Mailchimp::API.new(api_key)
    end
    @mailchimp_api
  rescue
    return nil
  end

  def self.ping(key)
    Rails.cache.fetch(['MailchimpAPITest', key]) do
      Mailchimp::API.new(key).helper.ping['msg'] == "Everything's Chimpy!"
    end
  rescue
    false
  end
end