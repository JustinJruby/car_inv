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

  # Sale rules (spec 004, US1). Tests come before the model changes.
  def sold_car(**attrs)
    car = build_car(status: :sold, **attrs)
    car.changed_by = users(:one)
    car
  end

  test "a sold car requires a sale price" do
    car = sold_car
    car.sale_price_cents = nil
    refute car.valid?
    assert car.errors[:sale_price_cents].any?
  end

  test "a sale price must be greater than zero" do
    car = sold_car
    car.sale_price = "0"
    refute car.valid?
  end

  test "a sale price with more than two decimal places is rejected, not rounded" do
    car = sold_car
    car.sale_price = "19.999"
    refute car.valid?
    assert_includes car.errors[:sale_price], "must be in dollars and cents"
    assert_nil car.sale_price_cents
  end

  test "a sale price with two decimal places is stored as cents" do
    car = sold_car
    car.sale_price = "19999.99"
    car.save!
    assert_equal 1_999_999, car.sale_price_cents
  end

  test "a dealer cost with more than two decimal places is an error, not dropped" do
    car = build_car
    car.dealer_cost = "12.345"
    refute car.valid?
    assert_includes car.errors[:dealer_cost], "must be in dollars and cents"
  end

  test "marking a car sold sets the sale date and copies the asking price at sale" do
    car = build_car(status: :available)
    car.save!
    car.changed_by = users(:one)
    car.status = :sold
    car.sale_price = "19000"
    car.save!
    assert_not_nil car.sold_at
    assert_equal car.asking_price_cents, car.asking_price_at_sale_cents
  end

  test "a pre-feature sold car with no sale price cannot be saved for another change" do
    car = cars(:honda_sold)
    car.changed_by = users(:one)
    car.make = "Accord"
    refute car.valid?
    assert car.errors[:sale_price_cents].any?
  end

  test "pricing a pre-feature sold car sets its listed price at sale so the difference shows" do
    car = cars(:honda_sold)
    car.changed_by = users(:one)
    car.sale_price = "15000"
    car.save!
    assert_equal car.asking_price_cents, car.asking_price_at_sale_cents
    assert_not_nil car.sold_at
  end

  test "the first listed price is set once and never changes" do
    car = build_car(asking_price_cents: 2_000_000)
    car.save!
    assert_equal 2_000_000, car.first_listed_price_cents

    car.update!(asking_price_cents: 1_800_000)
    assert_equal 2_000_000, car.reload.first_listed_price_cents
  end

  test "a later asking price change leaves the sale snapshot unchanged" do
    car = sold_car(asking_price_cents: 2_000_000)
    car.sale_price = "19000"
    car.save!
    car.update!(asking_price_cents: 1_500_000)
    assert_equal 2_000_000, car.reload.asking_price_at_sale_cents
  end

  test "a correction to a sold car's sale price writes a sale_price_corrected event" do
    car = sold_car
    car.sale_price = "19000"
    car.save!
    car.sale_price = "18500"
    car.save!
    assert_equal "sale_price_corrected", car.car_price_events.order(:id).last.kind
  end

  test "changing a sold car's status clears the sale and writes sale_price_cleared" do
    car = sold_car
    car.sale_price = "19000"
    car.save!
    car.changed_by = users(:one)
    car.status = :available
    car.save!
    car.reload
    assert_nil car.sale_price_cents
    assert_nil car.sold_at
    assert_nil car.asking_price_at_sale_cents
    assert_equal "sale_price_cleared", car.car_price_events.order(:id).last.kind
    assert_equal 1_900_000, car.car_price_events.order(:id).last.from_cents
  end

  test "dealer cost writes dealer_cost_set, then dealer_cost_changed" do
    car = build_car
    car.changed_by = users(:one)
    car.dealer_cost = "12000"
    car.save!
    assert_equal "dealer_cost_set", car.car_price_events.order(:id).last.kind
    car.dealer_cost = "11000"
    car.save!
    assert_equal "dealer_cost_changed", car.car_price_events.order(:id).last.kind
  end

  # The difference (spec 004, US2, T018). Measured against the asking price at the moment of sale.
  def difference_car(asking_at_sale:, sale:)
    car = build_car(status: :sold, asking_price_at_sale_cents: asking_at_sale, sale_price_cents: sale,
      sold_at: Time.current)
    car
  end

  test "the difference is the sale price minus the asking price at sale" do
    car = difference_car(asking_at_sale: 2_000_000, sale: 1_900_000)
    assert_equal(-100_000, car.sale_difference_cents)
  end

  test "the percentage is rounded to one decimal place" do
    car = difference_car(asking_at_sale: 3_000_00, sale: 2_000_00)
    assert_equal(-33.3, car.sale_difference_percent)
  end

  test "the label says below, above, or equal to listed" do
    assert_equal "below listed", difference_car(asking_at_sale: 2_000_000, sale: 1_900_000).sale_difference_label
    assert_equal "above listed", difference_car(asking_at_sale: 2_000_000, sale: 2_100_000).sale_difference_label
    assert_equal "equal to listed", difference_car(asking_at_sale: 2_000_000, sale: 2_000_000).sale_difference_label
  end

  test "a sold car with no asking price at sale has no difference and shows not available" do
    car = difference_car(asking_at_sale: nil, sale: 1_900_000)
    assert_nil car.sale_difference_cents
    assert_nil car.sale_difference_percent
    assert_equal "not available", car.sale_difference_label
  end
end
