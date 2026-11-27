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

ActiveRecord::Schema[8.1].define(version: 2026_11_26_400001) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "car_features", force: :cascade do |t|
    t.integer "car_id", null: false
    t.integer "feature_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["car_id", "feature_id"], name: "index_car_features_on_car_id_and_feature_id", unique: true
    t.index ["car_id"], name: "index_car_features_on_car_id"
    t.index ["feature_id"], name: "index_car_features_on_feature_id"
  end

  create_table "car_price_events", force: :cascade do |t|
    t.integer "car_id", null: false
    t.integer "user_id", null: false
    t.string "kind", null: false
    t.integer "from_cents"
    t.integer "to_cents"
    t.datetime "created_at", null: false
    t.index ["car_id"], name: "index_car_price_events_on_car_id"
    t.index ["user_id"], name: "index_car_price_events_on_user_id"
  end

  create_table "cars", force: :cascade do |t|
    t.integer "dealership_id", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.integer "year", null: false
    t.string "vin", limit: 17, null: false
    t.integer "mileage"
    t.integer "asking_price_cents"
    t.integer "status", default: 0, null: false
    t.datetime "price_dropped_at"
    t.string "contact_name"
    t.string "contact_phone"
    t.string "contact_email"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sale_price_cents"
    t.datetime "sold_at"
    t.integer "asking_price_at_sale_cents"
    t.integer "first_listed_price_cents"
    t.integer "dealer_cost_cents"
    t.index ["dealership_id"], name: "index_cars_on_dealership_id"
    t.index ["vin"], name: "index_cars_on_vin_unless_sold", unique: true, where: "status != 2"
  end

  create_table "dealerships", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dealerships_on_name", unique: true
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "car_id", null: false
    t.string "visitor_id", limit: 36, null: false
    t.datetime "saved_at", null: false
    t.datetime "removed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["car_id", "visitor_id"], name: "index_favorites_on_car_and_visitor_active", unique: true, where: "removed_at IS NULL"
    t.index ["car_id"], name: "index_favorites_on_car_id"
  end

  create_table "features", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_features_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transit_events", force: :cascade do |t|
    t.integer "transit_id", null: false
    t.integer "user_id", null: false
    t.string "kind", null: false
    t.string "from_value"
    t.string "to_value"
    t.datetime "created_at", null: false
    t.index ["transit_id"], name: "index_transit_events_on_transit_id"
    t.index ["user_id"], name: "index_transit_events_on_user_id"
  end

  create_table "transits", force: :cascade do |t|
    t.integer "car_id", null: false
    t.integer "dealership_id", null: false
    t.string "origin", limit: 120, null: false
    t.date "expected_arrival_on", null: false
    t.integer "state", default: 0, null: false
    t.boolean "pre_sell", default: false, null: false
    t.integer "pre_sell_price_cents"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["car_id"], name: "index_transits_on_car_id"
    t.index ["car_id"], name: "index_transits_on_car_id_unless_closed", unique: true, where: "state = 0"
    t.index ["dealership_id"], name: "index_transits_on_dealership_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "car_features", "cars"
  add_foreign_key "car_features", "features"
  add_foreign_key "car_price_events", "cars"
  add_foreign_key "car_price_events", "users"
  add_foreign_key "cars", "dealerships"
  add_foreign_key "favorites", "cars"
  add_foreign_key "sessions", "users"
  add_foreign_key "transit_events", "transits"
  add_foreign_key "transit_events", "users"
  add_foreign_key "transits", "cars"
  add_foreign_key "transits", "dealerships"
end
