class SyncController < ApplicationController
  def create
    date = params[:date].present? ? Date.parse(params[:date]) : nil
    HubstaffSyncJob.perform_later(date: date)
    label = date ? date.strftime("%B %d, %Y") : "the last 24 hours"
    redirect_back fallback_location: root_path, notice: "Sync started for #{label}. Data will update in a moment."
  end
end
