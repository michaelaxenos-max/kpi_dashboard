require "corepulse/version"
require "corepulse/configuration"
require "corepulse/kpi_calculator"
require "corepulse/multi_day_task_metadata"
require "corepulse/hubstaff_client"
require "corepulse/hubstaff_sync_service"
require "corepulse/task_type_sync_service"

# The host app, its rake tasks, and its views reference some of these unqualified
# (e.g. `KpiCalculator.task_kpi`, `HubstaffClient.new`, `HubstaffSyncService.new`),
# so expose top-level aliases alongside the namespaced constants.
KpiCalculator       = CorePulse::KpiCalculator       unless defined?(KpiCalculator)
HubstaffClient      = CorePulse::HubstaffClient      unless defined?(HubstaffClient)
HubstaffSyncService = CorePulse::HubstaffSyncService unless defined?(HubstaffSyncService)
