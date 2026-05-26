class TimeEntry < ApplicationRecord
  belongs_to :team_member
  belongs_to :project

  validates :date, presence: true
  validates :hours, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :team_member_id, uniqueness: { scope: [ :project_id, :date ] }
end
