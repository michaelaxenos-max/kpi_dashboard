module TeamMembers
  class PeriodData
    attr_reader :member, :period, :reference_date

    def initialize(member, period:, reference_date:)
      @member         = member
      @period         = period
      @reference_date = reference_date
    end

    def call
      self
    end

    def start_date
      @start_date ||= period == "week" ? reference_date.beginning_of_week(:monday) : reference_date.beginning_of_month
    end

    def end_date
      @end_date ||= period == "week" ? start_date + 6.days : reference_date.end_of_month
    end

    def days
      @days ||= (start_date..end_date).to_a
    end

    def kpi_by_date
      @kpi_by_date ||= CorePulse::KpiCalculator.daily_kpis(period_tasks, context_tasks: period_context)
                                     .transform_keys { |(_mid, date)| date }
    end

    def monthly_kpi
      @monthly_kpi ||= average_kpi(
        CorePulse::KpiCalculator.daily_kpis(month_tasks, context_tasks: outside_tasks).values.compact
      )
    end

    def weekly_kpi
      @weekly_kpi ||= average_kpi(days.filter_map { |d| kpi_by_date[d] })
    end

    def summaries
      @summaries ||= member.daily_kpi_summaries
                           .where(date: start_date..end_date)
                           .index_by(&:date)
    end

    def multi_day_tasks
      @multi_day_tasks ||= CorePulse::MultiDayTaskMetadata.build(month_tasks + outside_tasks)
    end

    def tasks_by_date
      @tasks_by_date ||= period_tasks.group_by(&:date).transform_values do |tasks|
        tasks.group_by(&:project).transform_values do |proj_tasks|
          { visible: proj_tasks.select { |t| t.merged_into_id.nil? }, all: proj_tasks }
        end
      end
    end

    def untracked_by_date
      @untracked_by_date ||= build_untracked_by_date
    end

    def funnel_builder?
      member.team&.name == "Funnel Builders"
    end

    private

    def month_start = reference_date.beginning_of_month
    def month_end   = reference_date.end_of_month
    def period_range = start_date..end_date

    def month_tasks
      @month_tasks ||= member.hubstaff_tasks
        .includes(:task_type, :project, :merged_tasks)
        .where(date: month_start..month_end)
        .to_a
        .sort_by { |t| [t.date, t.project&.name.to_s, t.summary.to_s] }
    end

    def period_tasks
      @period_tasks ||= period == "week" ? month_tasks.select { |t| period_range.cover?(t.date) } : month_tasks
    end

    def outside_tasks
      @outside_tasks ||= load_outside_tasks
    end

    def load_outside_tasks
      ids = month_tasks.map(&:hubstaff_task_id).uniq
      return [] unless ids.any?
      member.hubstaff_tasks
        .includes(:task_type, :merged_tasks)
        .where(hubstaff_task_id: ids)
        .where.not(date: month_start..month_end)
        .to_a
    end

    def period_context
      @period_context ||= if period == "week"
        month_tasks.reject { |t| period_range.cover?(t.date) } + outside_tasks
      else
        outside_tasks
      end
    end

    def average_kpi(kpis)
      return nil unless kpis.any?
      (kpis.sum / kpis.size).round(2)
    end

    def build_untracked_by_date
      te_by_date_project = member.time_entries
        .where(date: start_date..end_date)
        .group(:date, :project_id).sum(:hours)

      untracked_projects = load_untracked_projects(te_by_date_project)

      te_by_date_project.each_with_object({}) do |((date, project_id), hours), result|
        task_project_ids = (tasks_by_date[date] || {}).keys.map(&:id)
        next if task_project_ids.include?(project_id)
        (result[date] ||= []) << { project: untracked_projects[project_id], hours: hours }
      end
    end

    def load_untracked_projects(te_by_date_project)
      ids = te_by_date_project.map { |(_, pid), _| pid }.uniq
      Project.where(id: ids).index_by(&:id)
    end
  end
end
