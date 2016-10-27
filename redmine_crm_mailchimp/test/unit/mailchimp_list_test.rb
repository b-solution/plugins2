require File.expand_path('../../test_helper', __FILE__)

class MailchimpListTest < ActiveSupport::TestCase
  
  def setup
    Setting.plugin_redmine_crm_mailchimp[:api_key] = '123abc-sw8'
    params = {
      'web_id' => 'web_id',
      'name' => 'List',
      'id' => '123456'
    }
    @mailchimp_list = MailchimpList.new(params)
    # Mock contact
    Struct.new("MockContact", :first_name, :last_name, :email)
    @contact = Struct::MockContact.new('Ben', 'Henderson', 'email@email.ru')
    @contact_2 = Struct::MockContact.new('BOB', 'SAP', 'email2@email.ru')
  end

  def test_subscribe
    stub_request(:post, "https://sw8.api.mailchimp.com/2.0/lists/subscribe.json").
      with(:body => '{"id":"123456","email":{"email":"email@email.ru"},"merge_vars":{"FNAME":"Ben","LNAME":"Henderson"},"email_type":"html","double_optin":false,"update_existing":false,"replace_interests":true,"send_welcome":false,"apikey":"123abc-sw8"}',
           :headers => {'Content-Type'=>'application/json', 'Host'=>'sw8.api.mailchimp.com:443', 'User-Agent'=>'excon/0.45.4'}).
      to_return(:status => 200, :body => '{"status":"success"}', :headers => {})
    
    assert_equal "{\"status\"=>\"success\"}", @mailchimp_list.subscribe(@contact).to_s
  end

  def test_bulk_subscribe
    stub_request(:post, "https://sw8.api.mailchimp.com/2.0/lists/batch-subscribe.json").
      with(:body => "{\"id\":\"123456\",\"batch\":[{\"email\":{\"email\":\"email@email.ru\"},\"merge_vars\":{\"FNAME\":\"Ben\",\"LNAME\":\"Henderson\"}},{\"email\":{\"email\":\"email2@email.ru\"},\"merge_vars\":{\"FNAME\":\"BOB\",\"LNAME\":\"SAP\"}}],\"double_optin\":false,\"update_existing\":false,\"replace_interests\":true,\"apikey\":\"123abc-sw8\"}",
           :headers => {'Content-Type'=>'application/json', 'Host'=>'sw8.api.mailchimp.com:443', 'User-Agent'=>'excon/0.45.4'}).
      to_return(:status => 200, :body => '{"status":"success"}', :headers => {})
    
    assert_equal "{\"status\"=>\"success\"}", @mailchimp_list.bulk_subscribe([@contact, @contact_2]).to_s    
  end

end
