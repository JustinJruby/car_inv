require "test_helper"

class Manage::SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  # Builds a sold car sold on the given date, with its listed price at sale and its sale price.
  def sold_car(vin:, sold_on:, asking:, sale:, dealer_cost: nil)
    car = Car.new(dealership: dealerships(:one), make: "Mazda", model: "CX-5", year: 2021, vin: vin,
      mileage: 1000, asking_price_cents: asking, status: :sold, sale_price_cents: sale,
      asking_price_at_sale_cents: asking, sold_at: Time.zone.parse(sold_on).noon, dealer_cost_cents: dealer_cost)
    car.changed_by = users(:one)
    car.save!
    car
  end

  test "signed-out visitors are sent to sign-in" do
    sign_out
    get manage_sales_path
    assert_redirected_to new_session_path
  end

  test "the report lists cars sold inside the range and leaves out cars sold outside it" do
    sold_car(vin: "JM3KFBCM5LSALE001", sold_on: "2026-11-05", asking: 2_000_000, sale: 1_900_000)
    sold_car(vin: "JM3KFBCM5LSALE002", sold_on: "2026-10-01", asking: 1_500_000, sale: 1_400_000)

    get manage_sales_path, params: { from: "2026-11-01", to: "2026-11-30" }
    assert_response :success
    assert_includes response.body, "JM3KFBCM5LSALE001"
    assert_no_match "JM3KFBCM5LSALE002", response.body
  end

  test "the range includes both of its end dates" do
    sold_car(vin: "JM3KFBCM5LSALE003", sold_on: "2026-11-30", asking: 2_000_000, sale: 1_900_000)
    get manage_sales_path, params: { from: "2026-11-01", to: "2026-11-30" }
    assert_includes response.body, "JM3KFBCM5LSALE003"
  end

  test "the totals show total listed at sale, total sold, and total difference" do
    sold_car(vin: "JM3KFBCM5LSALE004", sold_on: "2026-11-05", asking: 2_000_000, sale: 1_900_000)
    sold_car(vin: "JM3KFBCM5LSALE005", sold_on: "2026-11-06", asking: 1_500_000, sale: 1_400_000)

    get manage_sales_path, params: { from: "2026-11-01", to: "2026-11-30" }
    assert_includes response.body, "$35,000.00"
    assert_includes response.body, "$33,000.00"
    assert_includes response.body, "-$2,000.00"
  end

  test "an empty range shows the empty message" do
    get manage_sales_path, params: { from: "2026-01-01", to: "2026-01-31" }
    assert_response :success
    assert_includes response.body, "No sales in this period"
  end

  test "dealer cost never appears in the report" do
    sold_car(vin: "JM3KFBCM5LSALE006", sold_on: "2026-11-05", asking: 2_000_000, sale: 1_900_000, dealer_cost: 1_234_56)
    get manage_sales_path, params: { from: "2026-11-01", to: "2026-11-30" }
    assert_no_match "1,234.56", response.body
    assert_no_match "1234.56", response.body
  end
end
