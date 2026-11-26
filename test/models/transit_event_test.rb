require "test_helper"

class TransitEventTest < ActiveSupport::TestCase
  setup do
    @transit = Transit.create!(car: cars(:toyota), dealership: dealerships(:one),
      origin: "Auction, Phoenix", expected_arrival_on: Date.current + 7)
    @user = users(:one)
  end

  test "kind must be one of the six allowed values" do
    %w[recorded expected_arrival_changed pre_sell_set pre_sell_price_changed arrived cancelled].each do |kind|
      assert TransitEvent.new(transit: @transit, user: @user, kind: kind).valid?, kind
    end
    assert_not TransitEvent.new(transit: @transit, user: @user, kind: "teleported").valid?
  end

  test "transit and user are required" do
    assert_not TransitEvent.new(transit: nil, user: @user, kind: "recorded").valid?
    assert_not TransitEvent.new(transit: @transit, user: nil, kind: "recorded").valid?
  end

  test "events are written in the same transaction as the change" do
    assert_no_difference "TransitEvent.count" do
      assert_raises(ActiveRecord::RecordInvalid) do
        TransitEvent.transaction do
          @transit.reschedule!(@user, Date.current + 2)
          raise ActiveRecord::RecordInvalid.new(@transit)
        end
      end
    end
    assert_equal Date.current + 7, @transit.reload.expected_arrival_on
  end
end
