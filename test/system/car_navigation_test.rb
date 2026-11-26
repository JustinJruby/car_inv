require "application_system_test_case"

class CarNavigationSystemTest < ApplicationSystemTestCase
  # Regression: car links inside the inventory's turbo frame showed "Content missing" instead of the car.
  test "clicking a car on the inventory opens its page" do
    visit cars_path
    click_link "2021 Toyota RAV4"
    assert_text "RAV4"
    assert_no_text "Content missing"
    assert_current_path car_path(cars(:toyota))
  end
end
