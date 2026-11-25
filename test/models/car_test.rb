require "test_helper"

class CarTest < ActiveSupport::TestCase
  setup { @dealership = dealerships(:one) }

  def build_car(**attrs)
    Car.new({
      dealership: @dealership, make: "Mazda", model: "CX-5", year: 2020,
      vin: "JM3KFBCM5L0123456", mileage: 1000, asking_price_cents: 2_000_000, status: :available
    }.merge(attrs))
  end

  test "valid car" do
    assert build_car.valid?
  end

  test "vin is normalized to uppercase and trimmed" do
    car = build_car(vin: "  jm3kfbcm5l0123456 ")
    car.valid?
    assert_equal "JM3KFBCM5L0123456", car.vin
  end

  test "vin must be exactly 17 characters" do
    refute build_car(vin: "JM3KFBCM5L012345").valid?
    refute build_car(vin: "JM3KFBCM5L01234567").valid?
  end

  test "year must be at least 1900" do
    refute build_car(year: 1899).valid?
    assert build_car(year: 1900).valid?
  end

  test "asking price must be greater than zero" do
    refute build_car(asking_price_cents: 0).valid?
  end

  test "asking price accepts dollars and stores cents" do
    car = build_car(asking_price: "21000.50")
    assert_equal 2_100_050, car.asking_price_cents
    assert_equal 21000.50, car.asking_price
  end

  test "vin cannot duplicate an active car" do
    car = build_car(vin: cars(:toyota).vin)
    refute car.valid?
    assert_includes car.errors[:vin], "is already used by another active listing"
  end

  test "vin of a sold car can be listed again" do
    assert build_car(vin: cars(:honda_sold).vin).valid?
  end

  test "stale scope finds cars unchanged for 60 days" do
    cars(:toyota).update_columns(updated_at: 61.days.ago)
    assert_includes Car.stale, cars(:toyota)
    refute_includes Car.stale, cars(:subaru_reserved)
  end
end
