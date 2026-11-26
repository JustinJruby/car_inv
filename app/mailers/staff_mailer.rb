class StaffMailer < ApplicationMailer
  # Nightly report of listings unchanged for 60 days (FR-017).
  def stale_listings(user, cars)
    @user = user
    @cars = cars
    mail to: user.email_address, subject: "#{cars.size} listing(s) unchanged for 60 days"
  end
end
