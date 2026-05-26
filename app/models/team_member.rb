class TeamMember < ApplicationRecord
  belongs_to :team, optional: true

  has_many :time_entries, dependent: :destroy
  has_many :hubstaff_tasks, dependent: :destroy
  has_many :daily_kpi_summaries, dependent: :destroy

  scope :active, -> { where(active: true) }

  validates :hubstaff_user_id, presence: true, uniqueness: true
  validates :name, presence: true

  def monthly_kpi(year, month)
    summaries = daily_kpi_summaries
      .where(date: Date.new(year, month, 1)..Date.new(year, month, -1))
      .where.not(overall_kpi_percentage: nil)

    return nil if summaries.empty?

    summaries.average(:overall_kpi_percentage).round(2)
  end

  def weekly_kpi(week_start)
    summaries = daily_kpi_summaries
      .where(date: week_start..week_start + 6.days)
      .where.not(overall_kpi_percentage: nil)

    return nil if summaries.empty?

    summaries.average(:overall_kpi_percentage).round(2)
  end
end
