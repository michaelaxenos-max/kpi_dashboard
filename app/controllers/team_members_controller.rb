class TeamMembersController < ApplicationController
  def index
    @team_members = TeamMember.active.includes(:team).order(:name)
  end

  def show
    @member         = TeamMember.includes(:team).find(params[:id])
    @period         = params[:period] || "week"
    @reference_date = params[:date].present? ? Date.parse(params[:date]) : Date.today

    data = TeamMembers::PeriodData.new(@member, period: @period, reference_date: @reference_date).call

    @start_date        = data.start_date
    @end_date          = data.end_date
    @days              = data.days
    @kpi_by_date       = data.kpi_by_date
    @monthly_kpi       = data.monthly_kpi
    @weekly_kpi        = data.weekly_kpi
    @summaries         = data.summaries
    @multi_day_tasks   = data.multi_day_tasks
    @tasks_by_date     = data.tasks_by_date
    @untracked_by_date = data.untracked_by_date
    @is_funnel_builder = data.funnel_builder?
  end
end
