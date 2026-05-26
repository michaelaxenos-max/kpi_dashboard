class DailyKpiSummary < ApplicationRecord
  belongs_to :team_member

  validates :date, presence: true
  validates :team_member_id, uniqueness: { scope: :date }

  def self.recalculate_for(team_member, date)
    time_entries = team_member.time_entries.where(date: date)
    tasks        = team_member.hubstaff_tasks.where(date: date, merged_into_id: nil)

    find_or_initialize_by(team_member: team_member, date: date).tap do |summary|
      summary.total_hours     = time_entries.sum(:hours)
      summary.tasks_completed = tasks.size
      summary.save!
    end
  end
end
