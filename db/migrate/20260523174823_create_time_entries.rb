class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries do |t|
      t.references :team_member, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :hours, precision: 6, scale: 2, null: false
      t.timestamps
    end
    add_index :time_entries, [ :team_member_id, :project_id, :date ], unique: true
    add_index :time_entries, :date
  end
end
