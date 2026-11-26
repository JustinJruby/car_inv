class SharesController < ApplicationController
  allow_unauthenticated_access

  # Public, read-only car page for anyone with a valid link (FR-018, FR-019).
  # Contact details are never shown here.
  def show
    @car = Car.find_by_token_for(:share, params[:token])

    if @car.nil?
      render :expired, status: :gone
    end
  end
end
