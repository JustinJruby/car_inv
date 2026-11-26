require "test_helper"

class ContactPrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @car = cars(:toyota)
    @car.update!(contact_name: "Pat Seller", contact_phone: "555-0100", contact_email: "pat@example.test")
  end

  test "customer search results never show staff contact details" do
    get cars_path
    assert_includes response.body, "RAV4"
    assert_private_contact_hidden
  end

  test "customer car page never shows staff contact details" do
    get car_path(@car)
    assert_response :success
    assert_private_contact_hidden
  end

  test "staff edit page shows staff contact details" do
    sign_in_as(users(:one))
    get edit_manage_car_path(@car)
    assert_includes response.body, "pat@example.test"
  end

  private
    def assert_private_contact_hidden
      refute_includes response.body, "Pat Seller"
      refute_includes response.body, "555-0100"
      refute_includes response.body, "pat@example.test"
    end
end
