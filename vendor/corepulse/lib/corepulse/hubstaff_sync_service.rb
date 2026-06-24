require "date"

module CorePulse
  # Pulls one day of Hubstaff data into the host app's tables.
  #
  # Field mapping (verified against the live API):
  #   members            -> team_members           (by hubstaff_user_id; name from include=users)
  #   projects           -> projects               (by hubstaff_project_id; active = status == "active")
  #   daily_activities   -> time_entries           (grouped by user+project, hours = tracked/3600)
  #   daily_activities   -> hubstaff_tasks         (grouped by user+task,    hours = tracked/3600)
  #   task summary       -> task_type              (matched by exact name == summary)
  class HubstaffSyncService
    def initialize(date: Date.today, client: nil)
      @date   = date.is_a?(String) ? Date.parse(date) : date
      @client = client || HubstaffClient.new
    end

    def sync_all
      sync_members
      sync_projects
      sync_time_entries
      sync_tasks
      recalculate_kpi_summaries
    end

    def sync_members
      @client.members.each do |m|
        uid = m["user_id"].to_s
        next if uid.empty?

        record = member_model.find_or_initialize_by(hubstaff_user_id: uid)
        record.name = m["name"] if m["name"].to_s.strip != "" && (record.new_record? || record.name.to_s.strip == "")
        record.name = "User #{uid}" if record.name.to_s.strip == ""
        record.active = (m["status"] != "removed") if record.respond_to?(:active=)
        record.save! if record.changed?
      end
    end

    def sync_projects
      @client.projects.each do |p|
        record = project_model.find_or_initialize_by(hubstaff_project_id: p["id"].to_s)
        record.name   = p["name"]
        record.active = (p["status"] == "active") if record.respond_to?(:active=)
        record.save! if record.changed?
      end
    end

    def sync_time_entries
      members  = member_model.all.index_by { |m| m.hubstaff_user_id.to_s }
      projects = project_model.all.index_by { |p| p.hubstaff_project_id.to_s }

      seconds = Hash.new(0)
      daily_activities.each do |a|
        seconds[[a["user_id"].to_s, a["project_id"].to_s]] += a["tracked"].to_i
      end

      seconds.each do |(uid, pid), secs|
        member  = members[uid]
        project = projects[pid]
        next unless member && project

        entry = time_entry_model.find_or_initialize_by(team_member_id: member.id, project_id: project.id, date: @date)
        entry.hours = (secs / 3600.0).round(2)
        entry.save!
      end
    end

    def sync_tasks(task_meta: nil)
      task_meta ||= @client.tasks.index_by { |t| t["id"] }
      members     = member_model.all.index_by { |m| m.hubstaff_user_id.to_s }
      projects    = project_model.all.index_by { |p| p.hubstaff_project_id.to_s }
      task_types  = active_task_types.index_by(&:name)

      seconds = Hash.new(0)
      daily_activities.each do |a|
        tid = a["task_id"]
        next if tid.nil?
        seconds[[a["user_id"].to_s, tid]] += a["tracked"].to_i
      end

      seconds.each do |(uid, tid), secs|
        member = members[uid]
        next unless member

        meta    = task_meta[tid] || {}
        project = projects[meta["project_id"].to_s]
        next unless project # hubstaff_tasks.project_id is NOT NULL

        summary = meta["summary"]
        type    = summary ? task_types[summary] : nil

        record = hubstaff_task_model.find_or_initialize_by(
          hubstaff_task_id: tid.to_s, team_member_id: member.id, date: @date
        )
        record.project_id   = project.id
        record.task_type_id = type&.id
        record.summary      = summary
        record.hours_spent  = (secs / 3600.0).round(2)
        record.save!
      end
    end

    def recalculate_kpi_summaries
      return unless kpi_summary_model.respond_to?(:recalculate_for)

      member_ids  = hubstaff_task_model.where(date: @date).distinct.pluck(:team_member_id)
      member_ids |= time_entry_model.where(date: @date).distinct.pluck(:team_member_id)

      member_ids.each do |mid|
        member = member_model.find_by(id: mid)
        kpi_summary_model.recalculate_for(member, @date) if member
      end
    end

    private

    def daily_activities
      @daily_activities ||= @client.daily_activities(@date)
    end

    def active_task_types
      task_type_model.respond_to?(:active) ? task_type_model.active : task_type_model.all
    end

    def member_model
      CorePulse.config.member_model
    end

    def project_model
      CorePulse.config.project_model
    end

    def time_entry_model
      CorePulse.config.time_entry_model
    end

    def hubstaff_task_model
      CorePulse.config.hubstaff_task_model
    end

    def task_type_model
      CorePulse.config.task_type_model
    end

    def kpi_summary_model
      CorePulse.config.kpi_summary_model
    end
  end
end
