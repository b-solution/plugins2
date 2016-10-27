require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# Engines::Testing.set_fixture_path

module RedmineHelpdesk

  module TestHelper
    HELPDESK_FIXTURES_PATH = File.dirname(__FILE__) + '/fixtures/helpdesk_mailer'

    def submit_email(filename, options={})
      raw = IO.read(File.join(HELPDESK_FIXTURES_PATH, filename))
      MailHandler.receive(raw, options)
    end

    def submit_helpdesk_email(filename, options={})
      raw = IO.read(File.join(HELPDESK_FIXTURES_PATH, filename))
      HelpdeskMailer.receive(raw, options)
    end

    def helpdesk_uploaded_file(filename, mime)
      fixture_file_upload("../../plugins/redmine_contacts_helpdesk/test/fixtures/helpdesk_mailer/#{filename}", mime, true)
    end

    def last_email
      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      mail
    end

    def with_helpdesk_settings(options, &block)
      saved_settings = options.keys.inject({}) do |h, k|
        h[k] = case Setting.plugin_redmine_contacts_helpdesk[k]
          when Symbol, false, true, nil
            Setting.plugin_redmine_contacts_helpdesk[k]
          else
            Setting.plugin_redmine_contacts_helpdesk[k].dup
          end
        h
      end
      options.each {|k, v| Setting.plugin_redmine_contacts_helpdesk[k] = v}
      yield
    ensure
      saved_settings.each {|k, v| Setting.plugin_redmine_contacts_helpdesk[k] = v} if saved_settings
    end

  end

  class TestCase

    def self.create_fixtures(fixtures_directory, table_names, class_names = {})
      if ActiveRecord::VERSION::MAJOR >= 4
        ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, class_names = {})
      else
        ActiveRecord::Fixtures.create_fixtures(fixtures_directory, table_names, class_names = {})
      end
    end

    def self.prepare
      Role.where(:id => [1, 2, 3, 4]).each do |r|
        r.permissions << :view_contacts
        r.save
      end
      Role.where(:id => [1, 2]).each do |r|
        r.permissions << :edit_contacts
        r.save
      end

      Role.where(:id => [1, 2, 3]).each do |r|
        r.permissions << :view_deals
        r.save
      end
      Project.where(:id => [1, 2, 3, 4]).each do |project|
        EnabledModule.create(:project => project, :name => 'contacts')
        EnabledModule.create(:project => project, :name => 'deals')
        EnabledModule.create(:project => project, :name => 'contacts_helpdesk')
      end
    end

    def assert_error_tag(options={})
      assert_tag({:attributes => { :id => 'errorExplanation' }}.merge(options))
    end

  end
end