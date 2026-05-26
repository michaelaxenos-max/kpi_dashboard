class Project < ApplicationRecord
  has_many :time_entries, dependent: :destroy
  has_many :hubstaff_tasks, dependent: :destroy

  scope :active, -> { where(active: true) }

  validates :hubstaff_project_id, presence: true, uniqueness: true
  validates :name, presence: true
end
