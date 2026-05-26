class HubstaffSyncJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(date: nil)
    dates = date ? [ date ] : [ Date.yesterday, Date.today ]
    dates.each { |d| CorePulse::HubstaffSyncService.new(date: d).sync_all }
  end
end
