# Existing cars have no recorded first listed price. The current asking price is the best
# available value (research R3). This is data-only, so reversing it does nothing.
class BackfillFirstListedPrice < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE cars
      SET first_listed_price_cents = asking_price_cents
      WHERE first_listed_price_cents IS NULL AND asking_price_cents IS NOT NULL
    SQL
  end

  def down
  end
end
