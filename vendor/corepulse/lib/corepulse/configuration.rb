module CorePulse
  # Holds the host application's model classes (injected via CorePulse.configure)
  # plus Hubstaff / Syncer credentials. Everything is duck-typed so the gem never
  # references the app's constants directly.
  class Configuration
    attr_accessor :member_model, :project_model, :time_entry_model,
                  :hubstaff_task_model, :task_type_model, :team_model,
                  :kpi_summary_model,
                  :hubstaff_refresh_token, :hubstaff_org_id,
                  :syncer_url, :syncer_api_key, :syncer_path

    def initialize
      @hubstaff_refresh_token = ENV["HUBSTAFF_REFRESH_TOKEN"]
      @hubstaff_org_id        = ENV["HUBSTAFF_ORG_ID"]
      @syncer_url             = ENV["HUBSTAFF_SYNCER_URL"]
      @syncer_api_key         = ENV["HUBSTAFF_SYNCER_API_KEY"]
      @syncer_path            = ENV.fetch("HUBSTAFF_SYNCER_PATH", "task_types")
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    alias config configuration

    def configure
      yield(configuration)
    end
  end
end
