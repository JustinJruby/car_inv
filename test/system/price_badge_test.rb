require "application_system_test_case"

# The badge flow is covered in favorites_test.rb. This file checks the staff side:
# a price reduction made in the staff form sets the badge for customers.
class PriceBadgeSystemTest < ApplicationSystemTestCase
  test "a staff price reduction sets price_dropped_at for favorited cars" do
    sign_in_staff_in_browser

    car = cars(:toyota)
    visit edit_manage_car_path(car)
    fill_in "car[asking_price]", with: "20000.00"
    click_button "Update Car"
    assert_text "Car updated."

    assert_not_nil car.reload.price_dropped_at
  end
end
