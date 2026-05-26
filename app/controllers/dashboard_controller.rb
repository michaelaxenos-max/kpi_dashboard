class DashboardController < ApplicationController
  def index
    @teams          = Team.includes(:team_members).all
    @selected_team  = params[:team_id].present? ? Team.find(params[:team_id]) : nil
    @reference_date = params[:date].present? ? Date.parse(params[:date]) : Date.today

    data = Dashboard::PeriodData.new(
      selected_team:    @selected_team,
      period:           params[:period] || "week",
      reference_date:   @reference_date,
      start_date_param: params[:start_date],
      end_date_param:   params[:end_date]
    ).call

    @period                  = data.period
    @start_date              = data.start_date
    @end_date                = data.end_date
    @days                    = data.days
    @members_by_team         = data.members_by_team
    @kpi_by_member_date      = data.kpi_by_member_date
    @projects_by_member_date = data.projects_by_member_date
    @hours_by_member_date    = data.hours_by_member_date
  end
end
