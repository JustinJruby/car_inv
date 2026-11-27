class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :car, null: false, foreign_key: true
      t.string :visitor_id, limit: 36, null: false
      t.datetime :saved_at, null: false
      t.datetime :removed_at

      t.timestamps
    end

    # One active favorite per visitor per car (spec 006, FR-002 and the repeated-save edge case).
    add_index :favorites, [ :car_id, :visitor_id ], unique: true, where: "removed_at IS NULL",
      name: "index_favorites_on_car_and_visitor_active"
  end
end
