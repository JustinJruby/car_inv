class CreateTransits < ActiveRecord::Migration[8.1]
  def change
    create_table :transits do |t|
      t.references :car, null: false, foreign_key: true
      t.references :dealership, null: false, foreign_key: true
      t.string :origin, null: false, limit: 120
      t.date :expected_arrival_on, null: false
      t.integer :state, null: false, default: 0
      t.boolean :pre_sell, null: false, default: false
      t.integer :pre_sell_price_cents
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    # At most one open transit per car (FR-002, SC-005). Enforced by the database.
    add_index :transits, :car_id, unique: true, where: "state = 0", name: "index_transits_on_car_id_unless_closed"
  end
end
