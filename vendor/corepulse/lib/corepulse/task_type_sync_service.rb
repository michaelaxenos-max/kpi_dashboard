require "faraday"
require "json"

module CorePulse
  # Imports task-type templates from the external "Hubstaff Syncer" app
  # (HUBSTAFF_SYNCER_URL / HUBSTAFF_SYNCER_API_KEY). It upserts task types by name,
  # marks them synced, and archives previously-synced types no longer present.
  #
  # The Syncer's response is read flexibly: either a bare JSON array or an object
  # with a "task_types" key, each row carrying "name" and "standard_hours".
  # Failures raise CorePulse::TaskTypeSyncService::Error (the controller rescues it).
  class TaskTypeSyncService
    class Error < StandardError; end

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
      seen     = []

      rows.each do |row|
        name = (row["name"] || row[:name]).to_s.strip
        next if name.empty?
        seen << name

        standard = (row["standard_hours"] || row[:standard_hours] || 1).to_f
        record = task_type_model.find_or_initialize_by(name: name)
        record.standard_hours = standard
        record.synced   = true  if record.respond_to?(:synced=)
        record.archived = false if record.respond_to?(:archived=)

        if record.new_record? || record.changed?
          record.save!
          imported += 1
        else
          skipped += 1
        end
      end

      { imported: imported, skipped: skipped, archived: archive_missing(seen) }
    end

    private

    def fetch
      response = connection.get(@path) do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}" unless @api_key.empty?
        req.headers["Accept"] = "application/json"
      end
      raise Error, "Syncer GET #{@path} -> #{response.status}" unless response.success?

      body = JSON.parse(response.body)
      body.is_a?(Hash) ? Array(body["task_types"] || body["data"]) : Array(body)
    rescue Faraday::Error => e
      raise Error, "Could not reach Hubstaff Syncer at #{@url}: #{e.message}"
    rescue JSON::ParserError => e
      raise Error, "Hubstaff Syncer returned invalid JSON: #{e.message}"
    end

    def archive_missing(seen)
      return 0 unless task_type_model.respond_to?(:column_names)
      return 0 unless (%w[synced archived] - task_type_model.column_names).empty?

      scope = task_type_model.where(synced: true, archived: false)
      scope = scope.where.not(name: seen) if seen.any?
      scope.update_all(archived: true)
    end

    def connection
      @connection ||= Faraday.new(url: @url) { |f| f.options.timeout = 30 }
    end

    def task_type_model
      CorePulse.config.task_type_model
    end
  end
end
