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

ActiveRecord::Schema[8.1].define(version: 2026_02_25_192853) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agreement_acceptances", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "agreement_id", null: false
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["agreement_id"], name: "index_agreement_acceptances_on_agreement_id"
    t.index ["booking_id"], name: "index_agreement_acceptances_on_booking_id"
    t.index ["user_id"], name: "index_agreement_acceptances_on_user_id"
  end

  create_table "agreements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.integer "version", null: false
    t.index ["published_at"], name: "index_agreements_on_published_at"
  end

  create_table "booking_slots", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "slot_id", null: false
    t.index ["booking_id", "slot_id"], name: "index_booking_slots_on_booking_id_and_slot_id", unique: true
    t.index ["booking_id"], name: "index_booking_slots_on_booking_id"
    t.index ["slot_id"], name: "index_booking_slots_on_slot_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.boolean "admin_created", default: false, null: false
    t.bigint "agreement_id", null: false
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.text "notes"
    t.boolean "refunded", default: false, null: false
    t.string "status", default: "confirmed", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_payment_link_id"
    t.string "stripe_refund_id"
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["agreement_id"], name: "index_bookings_on_agreement_id"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_bookings_on_stripe_payment_intent_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "slots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "held_by_user_id"
    t.datetime "held_until"
    t.datetime "starts_at", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["held_by_user_id"], name: "index_slots_on_held_by_user_id"
    t.index ["held_until"], name: "index_slots_on_held_until"
    t.index ["starts_at"], name: "index_slots_on_starts_at"
    t.index ["status"], name: "index_slots_on_status"
  end

  create_table "studio_settings", force: :cascade do |t|
    t.integer "cancellation_hours", default: 24, null: false
    t.datetime "created_at", null: false
    t.integer "hourly_rate_cents", null: false
    t.text "studio_description"
    t.string "studio_name"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.string "phone"
    t.string "stripe_customer_id"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agreement_acceptances", "agreements"
  add_foreign_key "agreement_acceptances", "bookings"
  add_foreign_key "agreement_acceptances", "users"
  add_foreign_key "booking_slots", "bookings"
  add_foreign_key "booking_slots", "slots"
  add_foreign_key "bookings", "agreements"
  add_foreign_key "bookings", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "slots", "users", column: "held_by_user_id"
end
