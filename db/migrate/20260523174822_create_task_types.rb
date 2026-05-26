class CreateTaskTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :task_types do |t|
      t.string :name, null: false
      t.decimal :standard_hours, precision: 5, scale: 2, null: false
      t.references :team, foreign_key: true
      t.timestamps
    end
  end
end
