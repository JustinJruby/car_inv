require "test_helper"

# FR-009, FR-012, SC-004: sale prices, listed prices at sale, dealer cost, and the difference never
# reach customers. Customer pages show only available cars (and live pre-sells).
class SalePrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @car = cars(:toyota)
    @car.changed_by = users(:one)
    @car.update!(dealer_cost_cents: 1_234_56)
  end

  test "the public inventory never shows dealer cost, listed prices at sale, or differences" do
    get cars_path
    assert_response :success
    assert_no_match "1,234.56", response.body
    assert_no_match "Internal cost", response.body
    assert_no_match "Price history", response.body
    assert_no_match "Asking price at sale", response.body
  end

  test "a car page never shows dealer cost or sale history" do
    get car_path(@car)
    assert_response :success
    assert_no_match "1,234.56", response.body
    assert_no_match "Internal cost", response.body
    assert_no_match "Dealer cost", response.body
    assert_no_match "Price history", response.body
  end

  test "favorites never show dealer cost or sale history" do
    get favorites_path, params: { ids: @car.id.to_s }
    assert_response :success
    assert_no_match "1,234.56", response.body
    assert_no_match "Dealer cost", response.body
  end

  test "a sold car is not visible to customers at all" do
    @car.update!(status: :sold, sale_price_cents: 2_100_000, sold_at: Time.current)
    get car_path(@car)
    assert_response :not_found
    get cars_path
    assert_no_match @car.vin, response.body
  end
end
