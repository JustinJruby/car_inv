class CreateTransitEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :transit_events do |t|
      t.references :transit, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :from_value
      t.string :to_value
      t.datetime :created_at, null: false
    end
  end
end
