require "test_helper"

# FR-009: origin, expected-date history, transit events, and staff details never reach customers.
class TransitPrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @car = Car.create!(dealership: dealerships(:one), make: "Mazda", model: "Privacy", year: 2022,
      vin: "JM3KFBCM5LPRIV001", mileage: 800, status: :in_transit,
      contact_name: "Staff Person", contact_phone: "555-0100", contact_email: "staff@example.test")
    @transit = Transit.create!(car: @car, dealership: dealerships(:one), origin: "Auction, Phoenix",
      expected_arrival_on: Date.current + 7, pre_sell: true, pre_sell_price_cents: 2_100_000)
    @transit.transit_events.create!(user: users(:one), kind: "pre_sell_set", to_value: "2100000", created_at: Time.current)
  end

  def assert_no_private_details(body)
    refute_includes body, "Auction, Phoenix", "origin leaked to a customer page"
    refute_includes body, "Staff Person", "staff contact name leaked"
    refute_includes body, "555-0100", "staff contact phone leaked"
    refute_includes body, "staff@example.test", "staff contact email leaked"
    refute_includes body, "Pre sell set", "transit history leaked"
    refute_includes body, "pre_sell_set", "transit history leaked"
  end

  test "the public inventory never shows origin, history, or staff contact" do
    get cars_path
    assert_response :success
    assert_no_private_details(response.body)
  end

  test "a pre-sell car page never shows origin, history, or staff contact" do
    get car_path(@car)
    assert_response :success
    assert_no_private_details(response.body)
  end

  test "favorites never show origin, history, or staff contact" do
    post car_favorite_path(@car)
    get favorites_path
    assert_response :success
    assert_no_private_details(response.body)
  end
end
