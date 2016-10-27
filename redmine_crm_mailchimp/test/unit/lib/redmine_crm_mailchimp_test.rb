require File.expand_path('../../../test_helper', __FILE__)

class RedmineCrmMailchimpTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :queries
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineContacts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,                                                                                                                    
                                                                                                                    :queries])  
  def setup
    Setting.plugin_redmine_crm_mailchimp['mailchimp_query_assignments'] = [{ :contact_query_id => 4 }, { :contact_query_id => 5 }]
    @redmine_crm_mail_chimp = RedmineCrmMailchimp::Settings.new
  end

  def test_visible_queries
    assert_equal [4,5,3].sort , @redmine_crm_mail_chimp.visible_queries.map(&:id).sort
  end

end
