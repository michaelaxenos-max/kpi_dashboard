require "faraday"
require "json"

module CorePulse
  # Imports task-type templates from the external "Hubstaff Syncer" app
  # (HUBSTAFF_SYNCER_URL / HUBSTAFF_SYNCER_API_KEY).
  #
  # Real Syncer contract (app: discord_relay):
  #   GET <url>/api/task_templates
  #   Auth: header  X-Api-Key: <key>
  #   Body: { "task_templates": [ { "id", "name", "dynamic", "team" }, ... ] }
  #
  # IMPORTANT: the Syncer is authoritative for task-type *names* and *team*
  # assignment only. It does NOT send standard_hours — those are owned by this
  # dashboard and set manually. So this sync NEVER modifies standard_hours on an
  # existing task type; it only sets a default on brand-new ones.
  class TaskTypeSyncService
    class Error < StandardError; end

    DEFAULT_STANDARD_HOURS = 1.0

    def initialize(url: nil, api_key: nil, path: nil)
      @url     = (url || CorePulse.config.syncer_url).to_s
      @api_key = (api_key || CorePulse.config.syncer_api_key).to_s
      @path    = (path || CorePulse.config.syncer_path).to_s
    end

    def sync
      raise Error, "Hubstaff Syncer URL is not configured (HUBSTAFF_SYNCER_URL)" if @url.empty?

      rows = fetch
      imported = 0
      skipped  = 0

      rows.each do |row|
        name = (row["name"] || row[:name]).to_s.strip
        next if name.empty?

        team = team_for(row["team"] || row[:team])

        record = task_type_model.find_or_initialize_by(name: name)
        if record.new_record?
          # Syncer does not provide standard_hours; seed a safe default for new types.
          record.standard_hours = DEFAULT_STANDARD_HOURS
          record.archived = false if record.respond_to?(:archived=)
        end
        # On existing records, never touch standard_hours (owned here) or the
        # archived flag (a manual decision) — only refresh name->team + synced.
        record.team_id = team.id if team && record.respond_to?(:team_id=)
        record.synced  = true    if record.respond_to?(:synced=)

        if record.new_record?
          record.save!
          imported += 1
        else
          record.save! if record.changed?
          skipped += 1
        end
      end

      # NOTE: we deliberately do NOT archive task types missing from the feed.
      # The Syncer returns only base templates, not the granular/"dynamic"
      # expansions (e.g. "Image (from scratch) - 12 Image Ads"), so archiving by
      # absence would wrongly hide legitimately-used task types.
      { imported: imported, skipped: skipped, archived: 0 }
    end

    private

    def fetch
      response = connection.get(@path) do |req|
        req.headers["X-Api-Key"] = @api_key unless @api_key.empty?
        req.headers["Accept"] = "application/json"
      end
      raise Error, "Syncer GET #{@path} -> #{response.status}" unless response.success?

      body = JSON.parse(response.body)
      body.is_a?(Hash) ? Array(body["task_templates"] || body["data"]) : Array(body)
    rescue Faraday::Error => e
      raise Error, "Could not reach Hubstaff Syncer at #{@url}: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "Hubstaff Syncer returned invalid JSON: #{e.message}"
    end

    def team_for(name)
      name = name.to_s.strip
      return nil if name.empty? || team_model.nil?
      team_model.find_or_create_by(name: name)
    rescue StandardError
      nil
    end

    def connection
      @connection ||= Faraday.new(url: @url) { |f| f.options.timeout = 30 }
    end

    def task_type_model
      CorePulse.config.task_type_model
    end

    def team_model
      CorePulse.config.team_model
    end
  end
end
