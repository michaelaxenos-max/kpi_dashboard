module CorePulse
  # Detects Hubstaff tasks tracked across more than one day and, for every
  # day-instance of such a task, returns display metadata keyed by the row id.
  #
  #   build(tasks) => { task.id => {
  #     total_hours:, is_final:, final_date:, start_date:, day_count:
  #   } }
  #
  # Single-day tasks are intentionally absent from the hash (callers treat a nil
  # lookup as "ordinary single-day task").
  module MultiDayTaskMetadata
    module_function

    def build(tasks)
      grouped = Array(tasks).group_by { |t| [t.team_member_id, t.hubstaff_task_id] }
      meta = {}

      grouped.each_value do |instances|
        dates = instances.map(&:date).uniq
        next if dates.size <= 1

        total      = instances.reject { |t| t.merged_into_id }.sum { |t| t.hours_spent.to_f }
        final_date = dates.max
        start_date = dates.min

        instances.each do |t|
          meta[t.id] = {
            total_hours: total,
            is_final:    t.date == final_date,
            final_date:  final_date,
            start_date:  start_date,
            day_count:   dates.size
          }
        end
      end

      meta
    end
  end
end
