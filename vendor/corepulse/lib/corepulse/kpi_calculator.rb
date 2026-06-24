module CorePulse
  # KPI scoring.
  #
  # Meaning (from the dashboard legend): 100% == the task was completed in exactly
  # its task type's `standard_hours`. Faster than standard => above 100% (120%+ is
  # "bonus"); slower => below 100%.
  #
  #   task_kpi   = standard_hours / actual_hours * 100
  #
  # A day's KPI for a member is the hours-weighted roll-up of that day's scored
  # tasks (only tasks that have a task type — i.e. a standard to measure against):
  #
  #   daily_kpi  = (Σ standard_hours) / (Σ actual_hours) * 100
  #
  # Multi-day tasks (the same Hubstaff task tracked across several days) are scored
  # once, on their final day, against the TOTAL hours across all days. `context_tasks`
  # supplies the out-of-window day-instances so cross-day totals/final-dates are
  # correct even when the visible window clips a task.
  module KpiCalculator
    module_function

    # KPI for a single task given its type and the hours spent on it.
    def task_kpi(task_type, hours)
      return nil unless task_type
      actual = hours.to_f
      return nil unless actual.positive?
      standard = task_type.standard_hours.to_f
      return nil unless standard.positive?
      (standard / actual * 100).round(2)
    end

    # => { [team_member_id, date] => kpi_percentage_or_nil }
    def daily_kpis(tasks, context_tasks: [])
      tasks   = Array(tasks)
      grouped = (tasks + Array(context_tasks)).group_by { |t| [t.team_member_id, t.hubstaff_task_id] }
      acc     = Hash.new { |h, k| h[k] = { standard: 0.0, hours: 0.0 } }

      tasks.each do |task|
        next if task.merged_into_id            # absorbed into another task; counted via the keeper
        type = task.task_type
        next unless type
        standard = type.standard_hours.to_f
        next unless standard.positive?

        group      = grouped[[task.team_member_id, task.hubstaff_task_id]] || [task]
        final_date = group.map(&:date).max
        next unless task.date == final_date     # score only on the task's final day

        hours = group.sum { |t| t.hours_spent.to_f } + merged_hours(task)
        next unless hours.positive?

        bucket = acc[[task.team_member_id, task.date]]
        bucket[:standard] += standard
        bucket[:hours]    += hours
      end

      acc.transform_values do |v|
        v[:hours].positive? ? (v[:standard] / v[:hours] * 100).round(2) : nil
      end
    end

    # Same-day tasks merged INTO this one contribute their hours to its score.
    def merged_hours(task)
      return 0.0 unless task.respond_to?(:merged_tasks)
      task.merged_tasks.sum { |m| m.hours_spent.to_f }
    rescue StandardError
      0.0
    end
  end
end
