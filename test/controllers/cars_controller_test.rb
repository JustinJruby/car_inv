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
end
