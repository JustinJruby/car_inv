class CreateCarPriceEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :car_price_events do |t|
      t.references :car, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :from_cents
      t.integer :to_cents
      t.datetime :created_at, null: false
    end
  end
end
