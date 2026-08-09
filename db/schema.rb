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

ActiveRecord::Schema[8.1].define(version: 2026_08_09_091620) do
  create_table "contacts", force: :cascade do |t|
    t.integer "booked_trips", default: 0, null: false
    t.json "browse_destinations", default: []
    t.integer "clicks_30d", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "engagement_score", default: 0, null: false
    t.datetime "last_opened_at"
    t.string "name", null: false
    t.text "notes"
    t.integer "opens_30d", default: 0, null: false
    t.string "primary_destination"
    t.string "spend_band"
    t.json "tags", default: []
    t.string "trip_style"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_contacts_on_email", unique: true
    t.index ["primary_destination"], name: "index_contacts_on_primary_destination"
    t.index ["trip_style"], name: "index_contacts_on_trip_style"
  end

  create_table "discovery_runs", force: :cascade do |t|
    t.integer "contact_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "segment_count", default: 0, null: false
    t.string "status", default: "complete", null: false
    t.datetime "updated_at", null: false
  end

  create_table "insights", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "discovery_run_id", null: false
    t.string "kind", default: "trend", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discovery_run_id"], name: "index_insights_on_discovery_run_id"
  end

  create_table "segment_memberships", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.integer "segment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_segment_memberships_on_contact_id"
    t.index ["segment_id", "contact_id"], name: "index_segment_memberships_on_segment_id_and_contact_id", unique: true
    t.index ["segment_id"], name: "index_segment_memberships_on_segment_id"
  end

  create_table "segments", force: :cascade do |t|
    t.text "campaign_angle"
    t.string "campaign_subject"
    t.text "campaign_why"
    t.integer "contact_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "destination"
    t.integer "discovery_run_id", null: false
    t.string "name", null: false
    t.string "pattern_key"
    t.integer "position", default: 0, null: false
    t.json "reasons", default: []
    t.string "status", default: "proposed", null: false
    t.string "strength", default: "moderate", null: false
    t.string "trip_style"
    t.datetime "updated_at", null: false
    t.index ["discovery_run_id"], name: "index_segments_on_discovery_run_id"
    t.index ["pattern_key"], name: "index_segments_on_pattern_key"
    t.index ["status"], name: "index_segments_on_status"
  end

  add_foreign_key "insights", "discovery_runs"
  add_foreign_key "segment_memberships", "contacts"
  add_foreign_key "segment_memberships", "segments"
  add_foreign_key "segments", "discovery_runs"
end
