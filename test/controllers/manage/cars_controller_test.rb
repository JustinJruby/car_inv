require "test_helper"

class Manage::CarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @car = cars(:toyota)
  end

  def valid_attributes(**overrides)
    {
      dealership_id: dealerships(:one).id, make: "Mazda", model: "CX-5", year: 2020,
      vin: "JM3KFBCM5L0123456", mileage: 1000, asking_price: "20000.00", status: "available"
    }.merge(overrides)
  end

  test "create with valid attributes adds a car" do
    assert_difference("Car.count", 1) do
      post manage_cars_path, params: { car: valid_attributes }
    end
    assert_redirected_to manage_cars_path
  end

  test "create rejects a 16 character VIN" do
    assert_no_difference("Car.count") do
      post manage_cars_path, params: { car: valid_attributes(vin: "JM3KFBCM5L012345") }
    end
    assert_response :unprocessable_entity
  end

  test "update changes the asking price" do
    patch manage_car_path(@car), params: { car: { asking_price: "21000.00" } }
    assert_redirected_to manage_cars_path
    assert_equal 2_100_000, @car.reload.asking_price_cents
  end

  test "destroy removes the car" do
    assert_difference("Car.count", -1) do
      delete manage_car_path(@car)
    end
    assert_redirected_to manage_cars_path
  end

  # Sale recording (spec 004, US1, T010).
  test "marking a car sold with a sale price saves it and writes a sold event" do
    patch manage_car_path(@car), params: { car: { status: "sold", sale_price: "21000" } }
    assert_redirected_to manage_cars_path
    @car.reload
    assert @car.sold?
    assert_equal 2_100_000, @car.sale_price_cents
    assert_equal "sold", @car.car_price_events.order(:id).last.kind
    assert_equal users(:one), @car.car_price_events.order(:id).last.user
  end

  test "marking a car sold with no sale price is rejected and the car stays unsold" do
    patch manage_car_path(@car), params: { car: { status: "sold", sale_price: "" } }
    assert_response :unprocessable_entity
    assert @car.reload.available?
  end

  test "correcting a sale price writes a sale_price_corrected event with old and new values" do
    patch manage_car_path(@car), params: { car: { status: "sold", sale_price: "21000" } }
    patch manage_car_path(@car), params: { car: { sale_price: "20500" } }
    event = @car.reload.car_price_events.order(:id).last
    assert_equal "sale_price_corrected", event.kind
    assert_equal 2_100_000, event.from_cents
    assert_equal 2_050_000, event.to_cents
  end

  test "setting a dealer cost writes dealer_cost_set, and changing it writes dealer_cost_changed" do
    patch manage_car_path(@car), params: { car: { dealer_cost: "18000" } }
    assert_equal "dealer_cost_set", @car.reload.car_price_events.order(:id).last.kind
    patch manage_car_path(@car), params: { car: { dealer_cost: "17500" } }
    assert_equal "dealer_cost_changed", @car.reload.car_price_events.order(:id).last.kind
  end

  # The staff car page shows the difference (spec 004, US2, T019).
  test "the staff car page shows the listed price at sale, the sale price, and the difference label" do
    patch manage_car_path(@car), params: { car: { status: "sold", sale_price: "19000" } }
    get manage_car_path(@car)
    assert_response :success
    assert_includes response.body, "$24,500"
    assert_includes response.body, "$19,000"
    assert_includes response.body, "below listed"
  end

  test "a dealer cost with more than two decimal places is rejected, not dropped" do
    patch manage_car_path(@car), params: { car: { dealer_cost: "12.345" } }
    assert_response :unprocessable_entity
    assert_nil @car.reload.dealer_cost_cents
  end

  test "manage pages require sign in" do
    sign_out
    get manage_cars_path
    assert_redirected_to new_session_path
  end
end

class Manage::CarsStaleSaveTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "save with a stale lock_version is rejected and changes nothing" do
    car = cars(:toyota)
    stale_version = car.lock_version

    # Another staff member saves first, which bumps the version.
    Car.find(car.id).update!(mileage: 39_000)

    patch manage_car_path(car), params: { car: { asking_price: "1.00", lock_version: stale_version } }

    assert_response :unprocessable_entity
    assert_equal 2_450_000, car.reload.asking_price_cents
    assert_includes response.body, "changed by someone else"
  end
end
