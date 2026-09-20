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

ActiveRecord::Schema[8.1].define(version: 2026_09_20_205358) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.integer "attendance_status"
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["member_id"], name: "index_attendances_on_member_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "location"
    t.string "name"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
  end

  create_table "members", force: :cascade do |t|
    t.string "FirstName"
    t.date "JoinAt"
    t.string "LastName"
    t.boolean "carPoolStatus"
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "points"
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "updated_at", null: false
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
  add_foreign_key "rsvps", "members"
end
