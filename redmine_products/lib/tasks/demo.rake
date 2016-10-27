namespace :redmine do
  namespace :products do
    desc "Load demo data"
    task :load_demo_data => :environment do
      # Load fixtures
      require 'active_record/fixtures'
      demo_fixtures_dir = File.dirname(__FILE__) + '/../../db/demo/'
      Dir.glob(demo_fixtures_dir + '*.yml').each do |fixture_file|
        ActiveRecord::Fixtures.create_fixtures(demo_fixtures_dir, File.basename(fixture_file, '.*'))
      end
      Order.all.all?(&:save)
    end

  end
end