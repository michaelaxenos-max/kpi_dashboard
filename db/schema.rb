# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_24_044555) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "daily_kpi_summaries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "hours_target", precision: 5, scale: 2
    t.decimal "overall_kpi_percentage", precision: 7, scale: 2
    t.integer "tasks_completed", default: 0
    t.decimal "tasks_kpi_percentage", precision: 7, scale: 2
    t.bigint "team_member_id", null: false
    t.decimal "total_hours", precision: 6, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_kpi_summaries_on_date"
    t.index ["team_member_id", "date"], name: "index_daily_kpi_summaries_on_team_member_id_and_date", unique: true
    t.index ["team_member_id"], name: "index_daily_kpi_summaries_on_team_member_id"
  end

  create_table "hubstaff_tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "hours_spent", precision: 6, scale: 2
    t.string "hubstaff_task_id", null: false
    t.decimal "kpi_percentage", precision: 7, scale: 2
    t.bigint "merged_into_id"
    t.bigint "project_id", null: false
    t.string "summary"
    t.bigint "task_type_id"
    t.bigint "team_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hubstaff_task_id", "team_member_id", "date"], name: "index_hubstaff_tasks_unique_per_member_day", unique: true
    t.index ["project_id"], name: "index_hubstaff_tasks_on_project_id"
    t.index ["task_type_id"], name: "index_hubstaff_tasks_on_task_type_id"
    t.index ["team_member_id", "date"], name: "index_hubstaff_tasks_on_team_member_id_and_date"
    t.index ["team_member_id"], name: "index_hubstaff_tasks_on_team_member_id"
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "hubstaff_project_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["hubstaff_project_id"], name: "index_projects_on_hubstaff_project_id", unique: true
  end

  create_table "task_types", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "standard_hours", precision: 5, scale: 2, null: false
    t.boolean "synced", default: false, null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_task_types_on_team_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.decimal "daily_hours_target", precision: 5, scale: 2, default: "8.0"
    t.string "email"
    t.string "hubstaff_user_id", null: false
    t.string "name", null: false
    t.string "role"
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.index ["hubstaff_user_id"], name: "index_team_members_on_hubstaff_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "time_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "hours", precision: 6, scale: 2, null: false
    t.bigint "project_id", null: false
    t.bigint "team_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_time_entries_on_date"
    t.index ["project_id"], name: "index_time_entries_on_project_id"
    t.index ["team_member_id", "project_id", "date"], name: "index_time_entries_on_team_member_id_and_project_id_and_date", unique: true
    t.index ["team_member_id"], name: "index_time_entries_on_team_member_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "daily_kpi_summaries", "team_members"
  add_foreign_key "hubstaff_tasks", "projects"
  add_foreign_key "hubstaff_tasks", "task_types"
  add_foreign_key "hubstaff_tasks", "team_members"
  add_foreign_key "task_types", "teams"
  add_foreign_key "team_members", "teams"
  add_foreign_key "time_entries", "projects"
  add_foreign_key "time_entries", "team_members"
end
