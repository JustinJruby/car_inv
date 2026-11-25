class CreateCars < ActiveRecord::Migration[8.1]
  def change
    create_table :cars do |t|
      t.references :dealership, null: false, foreign_key: true
      t.string :make, null: false
      t.string :model, null: false
      t.integer :year, null: false
      t.string :vin, null: false, limit: 17
      t.integer :mileage, null: false, default: 0
      t.integer :asking_price_cents, null: false
      t.integer :status, null: false, default: 0
      t.datetime :price_dropped_at
      t.string :contact_name
      t.string :contact_phone
      t.string :contact_email
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    # VIN must be unique among cars that are not sold (status 2). See data-model.md: Car.vin.
    add_index :cars, :vin, unique: true, where: "status != 2", name: "index_cars_on_vin_unless_sold"
  end
end
