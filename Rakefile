namespace :db do
  require "sequel"
  Sequel.extension :migration
  DB = Sequel.connect(ENV['DATABASE_URL'])
  
  desc "Prints current schema version"
  task :version do    
    version = if DB.tables.include?(:schema_info)
      DB[:schema_info].first[:version]
    end || 0
 
    puts "Schema Version: #{version}"
  end
 
  desc "Perform migration up to latest migration available"
  task :migrate do
    Sequel::Migrator.run(DB, "migrations")
    Rake::Task['db:version'].execute
  end
    
  desc "Perform rollback to specified target or full rollback as default"
  task :rollback, :target do |t, args|
    args.with_defaults(:target => 0)
 
    Sequel::Migrator.run(DB, "migrations", :target => args[:target].to_i)
    Rake::Task['db:version'].execute
  end
 
  desc "Perform migration reset (full rollback and migration)"
  task :reset do
    Sequel::Migrator.run(DB, "migrations", :target => 0)
    Sequel::Migrator.run(DB, "migrations")
    Rake::Task['db:version'].execute
  end    
end

namespace :secret do
  require "securerandom"
  
  desc "Generate a new CSRF secret token"
  task :generate do
    puts SecureRandom.hex(64)  
  end
end

desc "Run the app on port 4567"
task :runserver do
  begin
    `rackup -p 4567`
  rescue Interrupt
    # Suppress "rake aborted" error on SIGINT
    sleep 0.5
  end
end