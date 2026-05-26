namespace :hubstaff do
  desc "Backfill Hubstaff data for the past N weeks (default 3)"
  task backfill: :environment do
    date_from = (ENV["WEEKS"] || 3).to_i.weeks.ago.to_date
    date_to   = Date.yesterday

    puts "Backfilling #{date_from} -> #{date_to} (#{(date_to - date_from).to_i + 1} days)"

    client  = HubstaffClient.new
    service = HubstaffSyncService.new(date: date_from)
    service.sync_members
    service.sync_projects

    puts "  Pre-loading task metadata..."
    task_meta = client.tasks.index_by { |t| t["id"] }
    puts "  Loaded #{task_meta.size} tasks"

    (date_from..date_to).each do |date|
      puts "  Syncing #{date}..."
      day = HubstaffSyncService.new(date: date)
      day.sync_time_entries
      day.sync_tasks(task_meta: task_meta)
      day.recalculate_kpi_summaries
    end

    puts "Done."
  end
end
