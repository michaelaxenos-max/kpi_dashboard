class AddArchivedToTaskTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :task_types, :archived, :boolean, default: false, null: false
  end
end
