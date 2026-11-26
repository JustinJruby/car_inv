require "test_helper"

class Manage::TransitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @dealership = dealerships(:one)
  end

  def valid_params(**overrides)
    {
      vin: "1HGCM82633A000111", make: "Subaru", model: "Outback", year: 2020,
      dealership_id: @dealership.id, origin: "Auction, Phoenix",
      expected_arrival_on: (Date.current + 7).iso8601
    }.merge(overrides)
  end

  # Builds an in-transit car and its transit directly, for setting up list and action tests.
  def transit_for(vin:, expected: Date.current + 7, state: :open, pre_sell: false, price: nil)
    car = Car.create!(dealership: @dealership, make: "Subaru", model: "Outback", year: 2020,
      vin: vin, mileage: 1000, status: :in_transit)
    transit = Transit.create!(car: car, dealership: @dealership, origin: "Auction, Phoenix",
      expected_arrival_on: expected, pre_sell: pre_sell, pre_sell_price_cents: price)
    transit.update_columns(state: Transit.states[state.to_s]) unless state == :open
    transit
  end

  # Staff must sign in (T013 and the signed-out case).
  test "signed-out visitors are sent to sign-in" do
    get manage_transits_path
    assert_redirected_to new_session_path
  end

  # US1 (T013): record a car in transit.
  test "recording a car creates it as in transit with an open transit and a recorded event" do
    sign_in_as @user
    assert_difference -> { Transit.count }, 1 do
      post manage_transits_path, params: { transit: valid_params }
    end
    transit = Transit.order(:id).last
    assert transit.open?
    assert transit.car.in_transit?
    assert_equal "recorded", transit.transit_events.last.kind
    assert_redirected_to manage_transit_path(transit)
  end

  test "recording a car whose VIN belongs to a non-sold car is rejected" do
    sign_in_as @user
    existing = cars(:toyota)
    assert_no_difference -> { Transit.count } do
      post manage_transits_path, params: { transit: valid_params(vin: existing.vin) }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "a car with this VIN is already in inventory or in transit"
  end

  test "a missing origin is rejected and the error names the field" do
    sign_in_as @user
    assert_no_difference -> { Transit.count } do
      post manage_transits_path, params: { transit: valid_params(origin: "") }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Origin"
  end

  # US2 (T017): the list.
  test "the list shows open transits by expected arrival and flags overdue ones" do
    sign_in_as @user
    transit_for(vin: "1HGCM82633A000201", expected: Date.current + 9)
    transit_for(vin: "1HGCM82633A000202", expected: Date.current - 2)
    transit_for(vin: "1HGCM82633A000203", expected: Date.current + 1)

    get manage_transits_path
    assert_response :success
    rows = css_select("tbody tr, li[data-transit]").map(&:text)
    assert_operator rows.index { |r| r.include?("000202") }, :<, rows.index { |r| r.include?("000203") }
    assert_select "[data-overdue=true], .badge-overdue", minimum: 1
  end

  test "the list shows the empty message when no cars are in transit" do
    sign_in_as @user
    get manage_transits_path
    assert_response :success
    assert_includes response.body, "No cars are in transit"
  end

  test "the list leaves out arrived and cancelled transits" do
    sign_in_as @user
    transit_for(vin: "1HGCM82633A000301", state: :arrived)
    transit_for(vin: "1HGCM82633A000302", state: :cancelled)
    get manage_transits_path
    assert_no_match "000301", response.body
    assert_no_match "000302", response.body
  end

  # US3 (T021): arrive, cancel, reschedule.
  test "arriving makes the car available at its pre-sell price and records the event" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000401", pre_sell: true, price: 2_100_000)
    post arrive_manage_transit_path(transit), params: { car: { mileage: 1200 } }
    assert_redirected_to manage_transit_path(transit)
    transit.reload
    assert transit.arrived?
    assert transit.car.reload.available?
    assert_equal 2_100_000, transit.car.asking_price_cents
    assert_equal "arrived", transit.transit_events.last.kind
  end

  test "arriving a transit for a sold car leaves the car sold and still records the arrival" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000402")
    transit.car.update_columns(status: Car.statuses[:sold])
    post arrive_manage_transit_path(transit), params: { car: { mileage: 1200, asking_price: "20000" } }
    assert transit.reload.arrived?
    assert transit.car.reload.sold?
    assert_equal "arrived", transit.transit_events.last.kind
  end

  test "arriving without the mileage and price the car still needs is rejected" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000403")
    post arrive_manage_transit_path(transit)
    assert_response :unprocessable_entity
    assert transit.reload.open?
  end

  test "cancelling leaves the car's own record unchanged" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000501")
    before = transit.car.reload.attributes.except("updated_at", "lock_version")
    post cancel_manage_transit_path(transit)
    assert transit.reload.cancelled?
    assert_equal before, transit.car.reload.attributes.except("updated_at", "lock_version")
    assert_equal "cancelled", transit.transit_events.last.kind
  end

  test "changing the expected date records the old and new dates" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000601", expected: Date.current + 3)
    patch expected_arrival_manage_transit_path(transit),
      params: { transit: { expected_arrival_on: (Date.current + 10).iso8601, lock_version: transit.lock_version } }
    event = transit.reload.transit_events.last
    assert_equal "expected_arrival_changed", event.kind
    assert_equal (Date.current + 10).iso8601, transit.expected_arrival_on.iso8601
  end

  test "arrived and cancelled transits reject further changes" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000701", state: :arrived)
    post cancel_manage_transit_path(transit)
    assert transit.reload.arrived?
    assert_redirected_to manage_transit_path(transit)
  end

  # US3 (T022): concurrency. A stale save is rejected with a reload message.
  test "a save based on a stale lock version asks staff to reload" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000801")
    stale = transit.lock_version
    transit.reschedule!(@user, Date.current + 5)  # another staff member's change bumps the version

    patch expected_arrival_manage_transit_path(transit),
      params: { transit: { expected_arrival_on: (Date.current + 9).iso8601, lock_version: stale } }
    assert_response :unprocessable_entity
    assert_includes response.body, "reload"
  end

  # US4 (T026): pre-sell.
  test "pre-sell without a price is rejected" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A000901")
    patch pre_sell_manage_transit_path(transit), params: { transit: { pre_sell_price: "" } }
    assert_response :unprocessable_entity
    assert_not transit.reload.pre_sell?
  end

  test "setting pre-sell records pre_sell_set, and changing the price records pre_sell_price_changed" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A001001")
    patch pre_sell_manage_transit_path(transit), params: { transit: { pre_sell_price: "21000" } }
    assert_equal "pre_sell_set", transit.reload.transit_events.last.kind
    patch pre_sell_manage_transit_path(transit), params: { transit: { pre_sell_price: "20500" } }
    assert_equal "pre_sell_price_changed", transit.reload.transit_events.last.kind
  end

  test "lowering the pre-sell price sets price_dropped_at on the car" do
    sign_in_as @user
    transit = transit_for(vin: "1HGCM82633A001101", pre_sell: true, price: 2_100_000)
    patch pre_sell_manage_transit_path(transit), params: { transit: { pre_sell_price: "20000" } }
    assert_not_nil transit.car.reload.price_dropped_at
  end
end
