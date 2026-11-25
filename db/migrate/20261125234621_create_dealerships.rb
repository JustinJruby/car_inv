class CreateDealerships < ActiveRecord::Migration[8.1]
  def change
    create_table :dealerships do |t|
      t.string :name

      t.timestamps
    end
    add_index :dealerships, :name, unique: true
  end
end
