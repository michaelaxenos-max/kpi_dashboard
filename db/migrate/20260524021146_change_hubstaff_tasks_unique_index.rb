class ChangeHubstaffTasksUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :hubstaff_tasks, :hubstaff_task_id
    add_index :hubstaff_tasks, [:hubstaff_task_id, :team_member_id, :date], unique: true, name: "index_hubstaff_tasks_unique_per_member_day"
  end
end
