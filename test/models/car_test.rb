require "test_helper"
require "turbo/broadcastable/test_helper"
class CarTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include Turbo::Broadcastable::TestHelper

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

  test "stale scope excludes a car changed 59 days ago" do
    cars(:toyota).update_columns(updated_at: 59.days.ago)
    refute_includes Car.stale, cars(:toyota)
  end

  test "stale scope finds cars unchanged for 60 days" do
    cars(:toyota).update_columns(updated_at: 61.days.ago)
    assert_includes Car.stale, cars(:toyota)
    refute_includes Car.stale, cars(:subaru_reserved)
  end

  test "a change broadcasts a refresh to the public list and the car page" do
    assert_turbo_stream_broadcasts("cars") do
      cars(:toyota).update!(mileage: 40_000)
    end
    assert_turbo_stream_broadcasts(cars(:toyota)) do
      cars(:toyota).update!(mileage: 41_000)
    end
  end

  test "a lower asking price sets price_dropped_at" do
    car = cars(:toyota)
    assert_nil car.price_dropped_at

    car.update!(asking_price: "21000.00")
    assert_not_nil car.reload.price_dropped_at
  end

  test "a higher asking price does not set price_dropped_at" do
    car = cars(:toyota)
    car.update!(asking_price: "30000.00")
    assert_nil car.reload.price_dropped_at
  end

  test "a price reduction sends no email" do
    assert_no_enqueued_emails do
      cars(:toyota).update!(asking_price: "20000.00")
    end
  end

  test "photos must be JPEG, PNG, or WebP" do
    car = cars(:toyota)
    car.new_photos = [ Rack::Test::UploadedFile.new(file_fixture("photo.png").to_s, "image/png") ]
    assert car.valid?

    car.new_photos = [ Rack::Test::UploadedFile.new(file_fixture("notes.txt").to_s, "text/plain") ]
    refute car.valid?
    assert_includes car.errors[:photos], "must be JPEG, PNG, or WebP"
  end

  test "a car in transit saves with only its intake fields" do
    car = build_car(status: :in_transit, mileage: nil, asking_price_cents: nil)
    assert car.valid?, car.errors.full_messages.to_sentence
  end

  test "a car in transit with an open pre-sell still needs mileage" do
    car = build_car(status: :in_transit)
    car.save!
    Transit.create!(car: car, dealership: @dealership, origin: "Auction, Phoenix",
      expected_arrival_on: Date.current + 7, pre_sell: true, pre_sell_price_cents: 2_100_000)
    car.reload
    car.mileage = nil
    refute car.valid?
    assert car.errors[:mileage].any?
  end

  test "stale report excludes cars in transit" do
    in_transit = cars(:toyota)
    in_transit.update_columns(status: Car.statuses[:in_transit], updated_at: 61.days.ago)
    listed = cars(:subaru_reserved)
    listed.update_columns(status: Car.statuses[:available], updated_at: 61.days.ago)

    assert_not_includes Car.stale, in_transit
    assert_includes Car.stale, listed
  end
end
