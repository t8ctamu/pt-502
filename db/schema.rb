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

ActiveRecord::Schema[8.1].define(version: 2026_10_10_172211) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "total_points_required", default: 7, null: false
    t.datetime "updated_at", null: false
    t.check_constraint "total_points_required >= 0", name: "app_settings_total_nonnegative"
  end

  create_table "attendances", force: :cascade do |t|
    t.integer "attendance_status"
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "member_id", null: false
    t.bigint "point_id"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["member_id", "event_id"], name: "index_attendances_on_member_id_and_event_id", unique: true
    t.index ["member_id"], name: "index_attendances_on_member_id"
    t.index ["point_id"], name: "index_attendances_on_point_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.integer "check_in_radius_meters", default: 100, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.decimal "latitude", precision: 10, scale: 6
    t.string "location"
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name"
    t.string "other_type"
    t.integer "point_value", default: 1, null: false
    t.bigint "requirement_id"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.index ["requirement_id"], name: "index_events_on_requirement_id"
    t.check_constraint "check_in_radius_meters > 0", name: "events_positive_radius"
    t.check_constraint "point_value >= 0", name: "events_nonnegative_points"
  end

  create_table "members", force: :cascade do |t|
    t.string "avatar_url"
    t.boolean "car_pool_status", default: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.date "joined_at"
    t.string "last_name"
    t.boolean "paid_dues", default: false, null: false
    t.datetime "profile_completed_at"
    t.date "pt_school_application_date"
    t.bigint "role_id", null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_members_on_role_id"
    t.index ["uid"], name: "index_members_on_uid", unique: true
  end

  create_table "points", force: :cascade do |t|
    t.date "awarded_date", null: false
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.string "note"
    t.integer "point_amount", null: false
    t.bigint "requirement_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_points_on_member_id"
    t.index ["requirement_id"], name: "index_points_on_requirement_id"
  end

  create_table "requirements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.integer "minimum_points", default: 0, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_requirements_on_name", unique: true
    t.check_constraint "minimum_points >= 0", name: "requirements_minimum_nonnegative"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "updated_at", null: false
    t.index ["description"], name: "index_roles_on_description", unique: true
  end

  create_table "rsvps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.date "respondedAt"
    t.boolean "response"
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_rsvps_on_member_id"
  end

  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "members"
  add_foreign_key "attendances", "points"
  add_foreign_key "events", "requirements"
  add_foreign_key "members", "roles"
  add_foreign_key "points", "members"
  add_foreign_key "points", "requirements"
  add_foreign_key "rsvps", "members"
end
