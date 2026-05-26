class AddDailyHoursTargetToTeamMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :team_members, :daily_hours_target, :decimal, precision: 5, scale: 2, default: 8.0
  end
end
