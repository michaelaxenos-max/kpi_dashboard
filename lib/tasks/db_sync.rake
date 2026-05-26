namespace :db do
  desc "Pull a snapshot of the production Supabase DB into local development"
  task sync_from_prod: :environment do
    prod_url = (ENV["SUPABASE_URL"] || ENV["DATABASE_URL"]).to_s.strip

    if prod_url.empty?
      abort "SUPABASE_URL is not set. Add your Supabase connection string to .env"
    end

    local_db = ActiveRecord::Base.configurations
      .find_db_config("development")
      .database

    dump_file = Rails.root.join("tmp", "prod_snapshot.dump")

    puts "=> Dumping production database..."
    system("pg_dump --no-owner --no-acl -Fc '#{prod_url}' -f '#{dump_file}'") or
      abort "pg_dump failed — check your DATABASE_URL and that pg_dump is installed"

    puts "=> Dropping and recreating local database: #{local_db}"
    system("dropdb --if-exists #{local_db}") or abort "dropdb failed"
    system("createdb #{local_db}") or abort "createdb failed"

    puts "=> Restoring snapshot into #{local_db}..."
    system("pg_restore --no-owner --no-acl -d #{local_db} '#{dump_file}'") or
      abort "pg_restore failed"

    File.delete(dump_file) if File.exist?(dump_file)

    puts "=> Done. Local DB is now a copy of production."
  end
end
