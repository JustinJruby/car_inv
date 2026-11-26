class StaleListingReportJob < ApplicationJob
  queue_as :default

  # Runs nightly from config/recurring.yml. Sends each staff member the cars unchanged for 60 days.
  def perform
    cars = Car.stale.includes(:dealership).order(:updated_at).to_a
    return if cars.empty?

    User.find_each do |user|
      StaffMailer.stale_listings(user, cars).deliver_later
    end
  end
end
