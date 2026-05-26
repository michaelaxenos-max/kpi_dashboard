class CreateHubstaffTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :hubstaff_tasks do |t|
      t.string :hubstaff_task_id, null: false
      t.references :team_member, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :task_type, foreign_key: true
      t.date :date, null: false
      t.decimal :hours_spent, precision: 6, scale: 2
      t.decimal :kpi_percentage, precision: 7, scale: 2
      t.string :summary
      t.timestamps
    end
    add_index :hubstaff_tasks, :hubstaff_task_id, unique: true
    add_index :hubstaff_tasks, [ :team_member_id, :date ]
  end
end
