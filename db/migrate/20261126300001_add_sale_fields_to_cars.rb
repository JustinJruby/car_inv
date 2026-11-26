class AddSaleFieldsToCars < ActiveRecord::Migration[8.1]
  def change
    add_column :cars, :sale_price_cents, :integer
    add_column :cars, :sold_at, :datetime
    add_column :cars, :asking_price_at_sale_cents, :integer
    add_column :cars, :first_listed_price_cents, :integer
    add_column :cars, :dealer_cost_cents, :integer
  end
end
