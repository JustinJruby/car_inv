require "test_helper"

class TransitTest < ActiveSupport::TestCase
  setup do
    @car = cars(:toyota)
    @user = users(:one)
  end

  def build_transit(**attrs)
    Transit.new({
      car: @car, dealership: dealerships(:one), origin: "Auction, Phoenix",
      expected_arrival_on: Date.current + 7
    }.merge(attrs))
  end

  test "valid transit" do
    assert build_transit.valid?
  end

  test "origin is required and limited to 120 characters" do
    assert_not build_transit(origin: "").valid?
    assert_not build_transit(origin: "x" * 121).valid?
    assert build_transit(origin: "x" * 120).valid?
  end

  test "expected arrival date is required" do
    transit = build_transit(expected_arrival_on: nil)
    assert_not transit.valid?
    assert transit.errors[:expected_arrival_on].any?
  end

  test "pre-sell requires a price greater than zero" do
    assert_not build_transit(pre_sell: true, pre_sell_price_cents: nil).valid?
    assert_not build_transit(pre_sell: true, pre_sell_price_cents: 0).valid?
    assert build_transit(pre_sell: true, pre_sell_price_cents: 2_100_000).valid?
  end

  test "a second open transit for the same car is rejected by validation" do
    build_transit.save!
    duplicate = build_transit
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:car_id], "already has an open transit"
  end

  test "the database rejects a second open transit for the same car" do
    build_transit.save!
    assert_raises(ActiveRecord::RecordNotUnique) do
      build_transit.save!(validate: false)
    end
  end

  test "a closed transit does not block a new open one for the same car" do
    first = build_transit
    first.save!
    first.arrive!(@user)
    assert build_transit.valid?
  end

  test "arrived and cancelled transits are final" do
    arrived = build_transit
    arrived.save!
    arrived.arrive!(@user)
    assert_raises(Transit::NotOpen) { arrived.reschedule!(@user, Date.current + 3) }

    cancelled = build_transit(car: cars(:subaru_reserved))
    cancelled.save!
    cancelled.cancel!(@user)
    assert_raises(Transit::NotOpen) { cancelled.cancel!(@user) }
  end

  test "overdue is true only for open transits past their expected date" do
    transit = build_transit(expected_arrival_on: Date.current - 1)
    transit.save!
    assert transit.overdue?

    transit.arrive!(@user)
    assert_not transit.overdue?
  end

  test "a future expected date is not overdue" do
    assert_not build_transit(expected_arrival_on: Date.current + 1).overdue?
  end

  test "public pre-sell needs an open transit, the pre-sell flag, and a price" do
    assert build_transit(pre_sell: true, pre_sell_price_cents: 2_100_000).public_pre_sell?
    assert_not build_transit(pre_sell: false, pre_sell_price_cents: 2_100_000).public_pre_sell?
  end

  test "arriving records an arrived event with the staff member" do
    transit = build_transit
    transit.save!
    assert_difference -> { transit.transit_events.count }, 1 do
      transit.arrive!(@user)
    end
    event = transit.transit_events.order(:id).last
    assert_equal "arrived", event.kind
    assert_equal @user, event.user
  end
end
