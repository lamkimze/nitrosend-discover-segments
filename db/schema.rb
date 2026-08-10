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

ActiveRecord::Schema[8.1].define(version: 2026_08_10_070000) do
  create_table "ai_analysis_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.integer "contact_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "model", default: "demo"
    t.integer "segments_found", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.json "summary", default: {}
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_ai_analysis_runs_on_status"
  end

  create_table "campaigns", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "segment_id", null: false
    t.string "status", default: "draft", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["segment_id"], name: "index_campaigns_on_segment_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "source", default: "import"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_contacts_on_email", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.json "metadata", default: {}
    t.datetime "occurred_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "event_type"], name: "index_events_on_contact_id_and_event_type"
    t.index ["contact_id"], name: "index_events_on_contact_id"
    t.index ["occurred_at"], name: "index_events_on_occurred_at"
  end

  create_table "segment_memberships", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.text "reason"
    t.decimal "score", precision: 5, scale: 4
    t.integer "segment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_segment_memberships_on_contact_id"
    t.index ["segment_id", "contact_id"], name: "index_segment_memberships_on_segment_id_and_contact_id", unique: true
    t.index ["segment_id"], name: "index_segment_memberships_on_segment_id"
  end

  create_table "segments", force: :cascade do |t|
    t.decimal "confidence_score", precision: 5, scale: 4, default: "0.0"
    t.integer "contact_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.json "evidence", default: []
    t.string "name", null: false
    t.string "slug"
    t.string "source", default: "ai", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_segments_on_slug", unique: true
    t.index ["source"], name: "index_segments_on_source"
    t.index ["status"], name: "index_segments_on_status"
  end

  add_foreign_key "campaigns", "segments"
  add_foreign_key "events", "contacts"
  add_foreign_key "segment_memberships", "contacts"
  add_foreign_key "segment_memberships", "segments"
end
