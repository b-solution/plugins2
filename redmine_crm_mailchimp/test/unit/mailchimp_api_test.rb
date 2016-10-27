require File.expand_path('../../test_helper', __FILE__)

class MailchimpApiTest < ActiveSupport::TestCase

  def test_instance
    # You must provide a MailChimp API key
    Setting.plugin_redmine_crm_mailchimp[:api_key] = nil
    assert_equal nil, MailchimpApi.instance.current
    
    # Your MailChimp API key must contain a suffix subdomain (e.g. "-us8").
    Setting.plugin_redmine_crm_mailchimp[:api_key] = 'sw8'
    assert_equal nil, MailchimpApi.instance.current

    Setting.plugin_redmine_crm_mailchimp[:api_key] = '123abc-sw8'
    assert_equal Mailchimp::API, MailchimpApi.instance.current.class    
  end

end
