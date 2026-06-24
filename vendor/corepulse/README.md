# corepulse (vendored)

Hubstaff sync + KPI engine for the KPI dashboard.

This is a **vendored, from-scratch reconstruction** of the original private
`garciajordy/corepulse` gem, rebuilt to match the exact interface the
`kpi_dashboard` app depends on. It is loaded via `path: "vendor/corepulse"` in the
app's Gemfile.

## What it provides

- `CorePulse.configure { |c| ... }` — inject the app's models (member, project,
  time_entry, hubstaff_task, task_type, team, kpi_summary).
- `CorePulse::KpiCalculator` (aliased top-level as `KpiCalculator`)
  - `task_kpi(task_type, hours)` → `standard_hours / hours * 100`
  - `daily_kpis(tasks, context_tasks:)` → `{ [member_id, date] => percent }`,
    hours-weighted, scoring multi-day tasks once on their final day.
- `CorePulse::MultiDayTaskMetadata.build(tasks)` → per-row multi-day display data.
- `CorePulse::HubstaffClient` (aliased `HubstaffClient`) — Hubstaff API v2 client
  (refresh-token auth, cursor pagination): `members`, `projects`, `tasks`,
  `daily_activities(date)`.
- `CorePulse::HubstaffSyncService` (aliased `HubstaffSyncService`) — one day of
  sync: `sync_all`, `sync_members`, `sync_projects`, `sync_time_entries`,
  `sync_tasks(task_meta:)`, `recalculate_kpi_summaries`.
- `CorePulse::TaskTypeSyncService.new.sync` — import task-type templates from the
  external Hubstaff Syncer app.

## Notes / fidelity

The original gem's source was unavailable, so the **KPI formula** here is a
faithful interpretation of the schema and dashboard legend (100% = met
`standard_hours`; 120%+ = bonus), not a byte-for-byte copy. The dashboard never
persisted KPI outputs, so the formula could not be fitted to stored values. The
Hubstaff field mappings were verified against the live API.

The Hubstaff Syncer (`HUBSTAFF_SYNCER_URL`) was unreachable at rebuild time; the
`TaskTypeSyncService` is implemented defensively and fails with a clear error if
the Syncer is unavailable. Task types already present in the database are
unaffected.
