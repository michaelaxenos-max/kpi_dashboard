Rails.application.config.after_initialize do
  CorePulse.configure do |config|
    config.member_model        = TeamMember
    config.project_model       = Project
    config.time_entry_model    = TimeEntry
    config.hubstaff_task_model = HubstaffTask
    config.task_type_model     = TaskType
    config.team_model          = Team
    config.kpi_summary_model   = DailyKpiSummary
  end
end
