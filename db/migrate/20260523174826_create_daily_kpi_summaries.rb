class CreateDailyKpiSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_kpi_summaries do |t|
      t.references :team_member, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :total_hours, precision: 6, scale: 2, default: 0
      t.decimal :tasks_kpi_percentage, precision: 7, scale: 2
      t.decimal :overall_kpi_percentage, precision: 7, scale: 2
      t.decimal :hours_target, precision: 5, scale: 2
      t.integer :tasks_completed, default: 0
      t.timestamps
    end
    add_index :daily_kpi_summaries, [ :team_member_id, :date ], unique: true
    add_index :daily_kpi_summaries, :date
  end
end
