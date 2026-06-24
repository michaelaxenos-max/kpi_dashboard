require "faraday"
require "json"
require "uri"
require "jwt"

module CorePulse
  # Thin Hubstaff API v2 client.
  #
  # Auth: exchanges a long-lived refresh token for a short-lived access token at
  # https://account.hubstaff.com/access_tokens, caching it until shortly before
  # its JWT `exp`. All data calls hit https://api.hubstaff.com/v2 and transparently
  # follow Hubstaff's cursor pagination (pagination.next_page_start_id -> page_start_id).
  class HubstaffClient
    ACCOUNTS_URL = "https://account.hubstaff.com".freeze
    API_URL      = "https://api.hubstaff.com".freeze
    PAGE_LIMIT   = 500

    class Error < StandardError; end

    def initialize(refresh_token: nil, org_id: nil)
      @refresh_token = (refresh_token || CorePulse.config.hubstaff_refresh_token).to_s
      @org_id        = (org_id || CorePulse.config.hubstaff_org_id).to_s
      raise Error, "Missing HUBSTAFF_REFRESH_TOKEN" if @refresh_token.empty?
      raise Error, "Missing HUBSTAFF_ORG_ID"        if @org_id.empty?
    end

    # => [{ "user_id" => Integer, "name" => String, "status" => String }, ...]
    def members
      users = {}
      memberships = []
      fetch_all("/v2/organizations/#{@org_id}/members", include: "users") do |body|
        Array(body["users"]).each { |u| users[u["id"]] = u["name"] }
        memberships.concat(Array(body["members"]))
      end
      memberships.map do |m|
        { "user_id" => m["user_id"], "name" => users[m["user_id"]], "status" => m["membership_status"] }
      end
    end

    # => [{ "id" =>, "name" =>, "status" => }, ...]
    def projects
      out = []
      fetch_all("/v2/organizations/#{@org_id}/projects", status: "active") do |body|
        out.concat(Array(body["projects"]))
      end
      out
    end

    # => [{ "id" =>, "project_id" =>, "summary" =>, ... }, ...]
    def tasks
      out = []
      fetch_all("/v2/organizations/#{@org_id}/tasks") do |body|
        out.concat(Array(body["tasks"]))
      end
      out
    end

    # All tracked activity for a single day.
    # => [{ "user_id" =>, "project_id" =>, "task_id" =>, "tracked" => seconds, "date" => }, ...]
    def daily_activities(date)
      d = date.respond_to?(:strftime) ? date.strftime("%Y-%m-%d") : date.to_s
      out = []
      fetch_all("/v2/organizations/#{@org_id}/activities/daily", date: { start: d, stop: d }) do |body|
        out.concat(Array(body["daily_activities"]))
      end
      out
    end

    private

    def fetch_all(path, params = {})
      start_id = nil
      loop do
        query = params.merge(page_limit: PAGE_LIMIT)
        query[:page_start_id] = start_id if start_id
        body = get(path, query)
        yield body
        start_id = body.dig("pagination", "next_page_start_id")
        break unless start_id
      end
    end

    def get(path, params = {})
      response = connection.get(path) do |req|
        req.params.update(params)
        req.headers["Authorization"] = "Bearer #{access_token}"
      end
      raise Error, "Hubstaff GET #{path} -> #{response.status}: #{response.body}" unless response.success?
      JSON.parse(response.body)
    end

    def access_token
      if @access_token && @token_expires_at && Time.now < (@token_expires_at - 60)
        return @access_token
      end

      response = Faraday.new(url: ACCOUNTS_URL).post("/access_tokens") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(grant_type: "refresh_token", refresh_token: @refresh_token)
      end
      raise Error, "Hubstaff token refresh failed -> #{response.status}: #{response.body}" unless response.success?

      data = JSON.parse(response.body)
      @access_token = data["access_token"]
      raise Error, "Hubstaff token refresh returned no access_token" if @access_token.to_s.empty?
      @token_expires_at = token_expiry(@access_token)
      @access_token
    end

    def token_expiry(token)
      payload, = JWT.decode(token, nil, false)
      Time.at(payload["exp"])
    rescue StandardError
      Time.now + 3600
    end

    def connection
      @connection ||= Faraday.new(url: API_URL) do |f|
        f.options.timeout = 60
        f.adapter Faraday.default_adapter
      end
    end
  end
end
