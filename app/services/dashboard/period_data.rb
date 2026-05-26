module Dashboard
  class PeriodData
    attr_reader :period, :start_date, :end_date

    def initialize(selected_team:, period:, reference_date:, start_date_param: nil, end_date_param: nil)
      @selected_team    = selected_team
      @reference_date   = reference_date
      @period, @start_date, @end_date = resolve_period(period, reference_date, start_date_param, end_date_param)
    end

    def call
      self
    end

    def days
      @days ||= (start_date..end_date).to_a
    end

    def members_by_team
      @members_by_team ||= members.order(:name).group_by(&:team)
    end

    def kpi_by_member_date
      @kpi_by_member_date ||= CorePulse::KpiCalculator.daily_kpis(period_tasks, context_tasks: outside_tasks)
    end

    def projects_by_member_date
      @projects_by_member_date ||= build_projects_by_member_date
    end

    def hours_by_member_date
      @hours_by_member_date ||= TimeEntry
        .where(team_member_id: member_ids, date: start_date..end_date)
        .group(:team_member_id, :date)
        .sum(:hours)
    end

    private

    def resolve_period(period, reference_date, start_param, end_param)
      if start_param.present? && end_param.present?
        s = Date.parse(start_param)
        e = Date.parse(end_param)
        e = s if e < s
        ["custom", s, e]
      elsif period == "week"
        s = reference_date.beginning_of_week(:monday)
        ["week", s, s + 6.days]
      else
        ["month", reference_date.beginning_of_month, reference_date.end_of_month]
      end
    end

    def members
      @members ||= @selected_team ? @selected_team.team_members.active : TeamMember.active.includes(:team)
    end

    def member_ids
      @member_ids ||= members.pluck(:id)
    end

    def period_tasks
      @period_tasks ||= HubstaffTask.includes(:task_type, :merged_tasks)
        .where(team_member_id: member_ids, date: start_date..end_date)
        .to_a
    end

    def outside_tasks
      @outside_tasks ||= load_outside_tasks
    end

    def load_outside_tasks
      ids = period_tasks.map(&:hubstaff_task_id).uniq
      return [] unless ids.any?
      HubstaffTask
        .where(team_member_id: member_ids, hubstaff_task_id: ids)
        .where.not(date: start_date..end_date)
        .select(:id, :team_member_id, :date, :hubstaff_task_id, :merged_into_id, :project_id, :hours_spent)
        .to_a
    end

    def build_projects_by_member_date
      all_tasks = period_tasks + outside_tasks
      final_date_by_hubstaff_id = all_tasks.group_by(&:hubstaff_task_id).transform_values { |rs| rs.map(&:date).max }

      period_tasks
        .reject { |t| t.merged_into_id.present? }
        .select { |t| final_date_by_hubstaff_id[t.hubstaff_task_id] == t.date }
        .group_by { |t| [t.team_member_id, t.date] }
        .transform_values { |ts| ts.map(&:project_id).uniq.size }
    end
  end
end
