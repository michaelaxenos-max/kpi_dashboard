class TaskType < ApplicationRecord
  belongs_to :team, optional: true

  has_many :hubstaff_tasks, dependent: :nullify

  scope :active, -> { where(archived: false) }

  validates :name, presence: true
  validates :standard_hours, presence: true, numericality: { greater_than: 0 }
end
