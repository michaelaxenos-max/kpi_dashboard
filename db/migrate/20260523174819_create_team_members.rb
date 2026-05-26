class CreateTeamMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :team_members do |t|
      t.string :hubstaff_user_id, null: false
      t.string :name, null: false
      t.string :email
      t.string :role
      t.references :team, foreign_key: true
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :team_members, :hubstaff_user_id, unique: true
  end
end
