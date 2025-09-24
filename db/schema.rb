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

ActiveRecord::Schema[8.0].define(version: 2025_09_24_041321) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bridge_routes", force: :cascade do |t|
    t.bigint "source_chain_id", null: false
    t.bigint "destination_chain_id", null: false
    t.decimal "fee_usd", precision: 10, scale: 4
    t.string "protocol", default: "stargate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_chain_id"], name: "index_bridge_routes_on_destination_chain_id"
    t.index ["source_chain_id", "destination_chain_id"], name: "idx_on_source_chain_id_destination_chain_id_3801d0b7fb"
    t.index ["source_chain_id"], name: "index_bridge_routes_on_source_chain_id"
  end

  create_table "chains", force: :cascade do |t|
    t.string "name", null: false
    t.integer "chain_id", null: false
    t.string "rpc_url", null: false
    t.string "native_token", default: "ETH", null: false
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id"], name: "index_chains_on_chain_id", unique: true
  end

  create_table "gas_readings", force: :cascade do |t|
    t.bigint "chain_id", null: false
    t.decimal "gas_price_gwei", precision: 20, scale: 9, null: false
    t.decimal "usd_cost", precision: 10, scale: 4
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id", "timestamp"], name: "index_gas_readings_on_chain_id_and_timestamp"
    t.index ["chain_id"], name: "index_gas_readings_on_chain_id"
    t.index ["timestamp"], name: "index_gas_readings_on_timestamp"
  end

  add_foreign_key "bridge_routes", "chains", column: "destination_chain_id"
  add_foreign_key "bridge_routes", "chains", column: "source_chain_id"
  add_foreign_key "gas_readings", "chains"
end
