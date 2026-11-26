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
