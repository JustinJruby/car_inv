require "test_helper"

class StaffMailerTest < ActionMailer::TestCase
  test "stale listings report lists the stale car" do
    car = cars(:toyota)
    car.update_columns(updated_at: 61.days.ago)

    email = StaffMailer.stale_listings(users(:one), [ car ])

    assert_equal [ users(:one).email_address ], email.to
    assert_match car.vin, email.body.to_s
  end
end
