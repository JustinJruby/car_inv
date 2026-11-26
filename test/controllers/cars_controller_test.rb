require "test_helper"

class CarsControllerTest < ActionDispatch::IntegrationTest
  test "index shows available cars without signing in" do
    get cars_path
    assert_response :success
    assert_includes response.body, "Toyota"
  end

  test "index hides reserved and sold cars" do
    get cars_path
    refute_includes response.body, "Honda"
    refute_includes response.body, "Subaru"
  end

  test "filters by make" do
    get cars_path, params: { make: "toyota" }
    assert_includes response.body, "Toyota"
    refute_includes response.body, "Honda"
  end

  test "filters by price range" do
    get cars_path, params: { min_price: 20_000, max_price: 25_000 }
    assert_includes response.body, "Toyota"

    get cars_path, params: { min_price: 30_000 }
    assert_includes response.body, "No cars match these filters."
  end

  test "filters by year" do
    get cars_path, params: { min_year: 2021 }
    assert_includes response.body, "Toyota"

    get cars_path, params: { max_year: 2019 }
    assert_includes response.body, "No cars match these filters."
  end

  test "filters by feature" do
    get cars_path, params: { feature: "awd" }
    assert_includes response.body, "Toyota"
  end

  test "reserved cars do not match a feature search" do
    get cars_path, params: { feature: "leather seats" }
    assert_includes response.body, "No cars match these filters."
    refute_includes response.body, "Subaru"
  end

  test "combines filters" do
    get cars_path, params: { make: "toyota", feature: "awd", max_price: 30_000 }
    assert_includes response.body, "Toyota"

    get cars_path, params: { make: "toyota", feature: "leather seats" }
    assert_includes response.body, "No cars match these filters."
  end

  test "show displays an available car" do
    get car_path(cars(:toyota))
    assert_response :success
    assert_includes response.body, "RAV4"
  end

  test "show does not expose a reserved car" do
    get car_path(cars(:subaru_reserved))
    assert_response :not_found
  end

  # Pre-sell visibility (spec 003, US4, T027).
  test "index includes a pre-sell car with a price and excludes a transit without one or not marked for pre-sell" do
    pre_sell = in_transit_car(model: "Aurora", pre_sell: true, price: 2_100_000)
    # The model forbids pre-sell without a price, so force that state directly to prove the query hides it.
    unpriced = in_transit_car(model: "Borealis")
    unpriced.open_transit.update_columns(pre_sell: true, pre_sell_price_cents: nil)
    not_pre_sell = in_transit_car(model: "Cascade")

    get cars_path
    assert_includes response.body, "Aurora"
    refute_includes response.body, "Borealis"
    refute_includes response.body, "Cascade"
    assert_includes response.body, "Pre-sell"
    assert_includes response.body, "$21,000"
    assert pre_sell.reload.in_transit?
    assert unpriced.reload.in_transit?
    assert not_pre_sell.reload.in_transit?
  end

  test "show displays a live pre-sell car with its price" do
    car = in_transit_car(model: "Aurora", pre_sell: true, price: 2_100_000)
    get car_path(car)
    assert_response :success
    assert_includes response.body, "$21,000"
  end

  test "cancelling the transit removes the pre-sell car from the public inventory" do
    car = in_transit_car(model: "Aurora", pre_sell: true, price: 2_100_000)
    car.open_transit.cancel!(users(:one))
    get cars_path
    refute_includes response.body, "Aurora"
    get car_path(car)
    assert_response :not_found
  end

  test "a saved pre-sell car is not shown as no longer available" do
    car = in_transit_car(model: "Aurora", pre_sell: true, price: 2_100_000)
    get favorites_path, params: { ids: car.id.to_s }
    assert_response :success
    assert_includes response.body, "Aurora"
    refute_includes response.body, "no longer available"
  end

  private

  # Builds an in-transit car with an open transit. Options control the pre-sell state.
  def in_transit_car(model:, pre_sell: false, price: nil)
    car = Car.create!(dealership: dealerships(:one), make: "Mazda", model: model, year: 2022,
      vin: "JM3KFBCM5L#{rand(1_000_000..9_999_999)}", mileage: 800, status: :in_transit)
    Transit.create!(car: car, dealership: dealerships(:one), origin: "Auction, Phoenix",
      expected_arrival_on: Date.current + 7, pre_sell: pre_sell, pre_sell_price_cents: price)
    car.reload # drop the cached open_transit, which was loaded before the transit existed
  end
end
