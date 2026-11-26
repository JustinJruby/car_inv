require "application_system_test_case"

class PreSellSystemTest < ApplicationSystemTestCase
  test "staff pre-sell an in-transit car, a customer sees it, and it becomes a normal listing on arrival" do
    car = Car.create!(dealership: dealerships(:one), make: "Mazda", model: "Sequoia", year: 2023,
      vin: "JM3KFBCM5LSYS0001", mileage: 900, status: :in_transit)
    transit = Transit.create!(car: car, dealership: dealerships(:one), origin: "Auction, Phoenix",
      expected_arrival_on: Date.current + 5)

    # Staff offer the car on pre-sell.
    sign_in_staff_in_browser
    visit manage_transit_path(transit)
    fill_in "transit_pre_sell_price", with: "21000"
    click_button "Offer pre-sell"
    assert_text "Pre-sell price saved"

    # A customer sees the pre-sell with its price, and never the origin.
    page.driver.browser.manage.delete_all_cookies
    visit cars_path
    assert_text "2023 Mazda Sequoia"
    assert_text "Pre-sell"
    assert_text "$21,000"
    assert_no_text "Auction, Phoenix"

    # Staff mark the car arrived. It becomes an ordinary listing at the same price.
    sign_in_staff_in_browser
    visit manage_transit_path(transit)
    fill_in "car[asking_price]", with: "21000"
    click_button "Mark arrived"
    assert_text "Car arrived"

    page.driver.browser.manage.delete_all_cookies
    visit cars_path
    assert_text "2023 Mazda Sequoia"
    assert_text "$21,000"
    assert_no_text "Pre-sell"
  end
end
