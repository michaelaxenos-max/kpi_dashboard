class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :hubstaff_project_id, null: false
      t.string :name, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :projects, :hubstaff_project_id, unique: true
  end
end
