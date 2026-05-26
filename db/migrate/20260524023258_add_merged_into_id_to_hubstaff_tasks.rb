class AddMergedIntoIdToHubstaffTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :hubstaff_tasks, :merged_into_id, :bigint
  end
end
