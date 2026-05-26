class HubstaffTask < ApplicationRecord
  belongs_to :team_member
  belongs_to :project
  belongs_to :task_type, optional: true
  belongs_to :merged_into, class_name: "HubstaffTask", optional: true
  has_many :merged_tasks, class_name: "HubstaffTask", foreign_key: :merged_into_id, dependent: :nullify

  validates :hubstaff_task_id, presence: true
  validates :hubstaff_task_id, uniqueness: { scope: [:team_member_id, :date] }
  validates :date, presence: true

  scope :visible, -> { where(merged_into_id: nil) }

  def display_hours
    hours_spent.to_f + merged_tasks.sum(:hours_spent)
  end
end
