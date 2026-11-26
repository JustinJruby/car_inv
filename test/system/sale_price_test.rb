require "application_system_test_case"

class SalePriceSystemTest < ApplicationSystemTestCase
  test "staff mark a listed car sold with a price and see the difference on the car page" do
    car = cars(:toyota)  # listed at $24,500

    sign_in_staff_in_browser
    visit edit_manage_car_path(car)
    select "Sold", from: "car_status"
    fill_in "car_sale_price", with: "23000"
    click_button "Update Car"
    assert_text "Car updated"

    visit manage_car_path(car)
    assert_text "Sale"
    assert_text "$23,000.00"
    assert_text "below listed"
  end
end
