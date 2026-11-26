require "test_helper"

class SharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @car = cars(:toyota)
    @car.update!(contact_name: "Pat Seller", contact_phone: "555-0100", contact_email: "pat@example.test")
  end

  test "a valid link shows the car without signing in" do
    token = @car.generate_token_for(:share)
    get share_path(token: token)

    assert_response :success
    assert_includes response.body, "RAV4"
  end

  test "an expired link shows a link expired message and no car details" do
    token = @car.generate_token_for(:share)

    travel 8.days do
      get share_path(token: token)
    end

    assert_response :gone
    assert_includes response.body, "expired"
    refute_includes response.body, "RAV4"
  end

  test "a made-up token is rejected" do
    get share_path(token: "not-a-real-token")
    assert_response :gone
  end

  test "the share page never shows staff contact details" do
    get share_path(token: @car.generate_token_for(:share))

    refute_includes response.body, "Pat Seller"
    refute_includes response.body, "555-0100"
    refute_includes response.body, "pat@example.test"
  end

  test "staff can create a share link for a car" do
    sign_in_as(users(:one))
    post manage_car_share_path(@car)

    assert_redirected_to edit_manage_car_path(@car)
    assert_match %r{/share/}, flash[:notice]
  end
end
