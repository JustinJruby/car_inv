require "test_helper"

class CarPriceEventTest < ActiveSupport::TestCase
  setup do
    @car = cars(:toyota)
    @user = users(:one)
  end

  test "kind accepts the five allowed values" do
    %w[sold sale_price_corrected sale_price_cleared dealer_cost_set dealer_cost_changed].each do |kind|
      assert CarPriceEvent.new(car: @car, user: @user, kind: kind).valid?, kind
    end
  end

  test "kind rejects any other value" do
    assert_not CarPriceEvent.new(car: @car, user: @user, kind: "discounted").valid?
  end

  test "car and user are required" do
    assert_not CarPriceEvent.new(car: nil, user: @user, kind: "sold").valid?
    assert_not CarPriceEvent.new(car: @car, user: nil, kind: "sold").valid?
  end
end
