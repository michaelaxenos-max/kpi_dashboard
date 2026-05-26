class Team < ApplicationRecord
  has_many :team_members, dependent: :destroy
  has_many :task_types, dependent: :destroy

  validates :name, presence: true
end
