class AddSyncedToTaskTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :task_types, :synced, :boolean, default: false, null: false
  end
end
