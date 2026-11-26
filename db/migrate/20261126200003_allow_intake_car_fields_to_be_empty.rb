# Cars in transit are recorded before their mileage and asking price are known (D1, option A).
# Both columns become nullable. Mileage also loses its default of 0, so intake cannot store a
# fake mileage. Listed cars still require both through model validations.
class AllowIntakeCarFieldsToBeEmpty < ActiveRecord::Migration[8.1]
  def change
    change_column_null :cars, :asking_price_cents, true
    change_column_null :cars, :mileage, true
    change_column_default :cars, :mileage, from: 0, to: nil
  end
end
