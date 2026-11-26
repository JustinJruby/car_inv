require "test_helper"

class StaleListingReportJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "emails each staff member the cars unchanged for 60 days" do
    cars(:toyota).update_columns(updated_at: 61.days.ago)

    assert_emails User.count do
      StaleListingReportJob.perform_now
    end
  end

  test "sends nothing when no car is stale" do
    Car.update_all(updated_at: Time.current)

    assert_emails 0 do
      StaleListingReportJob.perform_now
    end
  end
end
