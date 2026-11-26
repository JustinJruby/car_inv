# Staff pages for cars in transit (spec 003).
#
# D3 (option B): every signed-in staff member sees and changes transits for all dealerships.
# Scoping to a dealership is a follow-up, because staff accounts are not yet linked to one.
class Manage::TransitsController < ApplicationController
  ALREADY_LISTED = "a car with this VIN is already in inventory or in transit".freeze

  before_action :set_transit, only: %i[show arrive cancel expected_arrival pre_sell]

  def index
    @transits = Transit.open.includes(:car, :dealership).order(:expected_arrival_on)
  end

  def new
    @car = Car.new(status: :in_transit)
    @transit = Transit.new(expected_arrival_on: Date.current + 7)
  end

  def create
    dealership_id = intake_dealership_id
    @car = Car.new(intake_car_params.merge(status: :in_transit, dealership_id: dealership_id))
    @transit = Transit.new(intake_transit_params.merge(car: @car, dealership_id: dealership_id))

    if active_vin_taken?(@car.vin)
      @transit.errors.add(:base, ALREADY_LISTED)
      return render :new, status: :unprocessable_entity
    end

    # Validate both records before saving either, so the form shows every problem at once.
    unless [ @car.valid?, @transit.valid? ].all?
      return render :new, status: :unprocessable_entity
    end

    Transit.transaction do
      @car.save!
      @transit.save!
      @transit.transit_events.create!(user: Current.user, kind: "recorded", to_value: @transit.origin, created_at: Time.current)
    end
    redirect_to manage_transit_path(@transit), notice: "Car recorded as in transit."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
    @events = @transit.transit_events.includes(:user).order(:created_at)
  end

  def arrive
    apply_lock_version
    Transit.transaction do
      @transit.car.assign_attributes(arrival_car_params)
      @transit.arrive!(Current.user)
    end
    redirect_to manage_transit_path(@transit), notice: "Car arrived and is now in dealership inventory."
  rescue ActiveRecord::RecordInvalid
    @transit.reload
    flash.now[:alert] = "Enter the mileage and asking price before marking this car arrived."
    render :show, status: :unprocessable_entity
  rescue ActiveRecord::StaleObjectError
    stale_response
  rescue Transit::NotOpen => error
    redirect_to manage_transit_path(@transit), alert: error.message
  end

  def cancel
    @transit.cancel!(Current.user)
    redirect_to manage_transit_path(@transit), notice: "Transit cancelled. The car is unchanged."
  rescue Transit::NotOpen => error
    redirect_to manage_transit_path(@transit), alert: error.message
  end

  def expected_arrival
    apply_lock_version
    @transit.reschedule!(Current.user, parse_date(params.require(:transit)[:expected_arrival_on]))
    redirect_to manage_transit_path(@transit), notice: "Expected arrival updated."
  rescue ActiveRecord::StaleObjectError
    stale_response
  rescue Transit::NotOpen => error
    redirect_to manage_transit_path(@transit), alert: error.message
  rescue ActiveRecord::RecordInvalid
    @transit.reload
    flash.now[:alert] = "Enter a valid expected arrival date."
    render :show, status: :unprocessable_entity
  end

  def pre_sell
    price_cents = dollars_to_cents(params.require(:transit)[:pre_sell_price])
    @transit.set_pre_sell!(Current.user, price_cents)
    redirect_to manage_transit_path(@transit), notice: "Pre-sell price saved. Customers can now see this car."
  rescue ActiveRecord::RecordInvalid => error
    @transit.reload
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  rescue Transit::NotOpen => error
    redirect_to manage_transit_path(@transit), alert: error.message
  end

  private

  def set_transit
    @transit = Transit.find(params[:id])
  end

  def intake_car_params
    params.require(:transit).permit(:vin, :make, :model, :year).tap do |p|
      p[:vin] = p[:vin].to_s
    end
  end

  def intake_transit_params
    params.require(:transit).permit(:origin, :expected_arrival_on)
  end

  def intake_dealership_id
    params.require(:transit)[:dealership_id].presence || Dealership.first&.id
  end

  def arrival_car_params
    params.fetch(:car, {}).permit(:mileage, :asking_price)
  end

  # Concurrency (research R6): the form sends the version it was loaded with.
  def apply_lock_version
    version = params.dig(:transit, :lock_version)
    @transit.lock_version = version if version.present?
  end

  def active_vin_taken?(vin)
    Car.where(vin: vin.to_s.strip.upcase).where.not(status: :sold).exists?
  end

  def stale_response
    @transit.reload
    flash.now[:alert] = "This transit was changed by someone else. Reload the page and try again."
    render :show, status: :unprocessable_entity
  end

  def dollars_to_cents(value)
    return nil if value.blank?
    (BigDecimal(value.to_s) * 100).round
  rescue ArgumentError
    nil
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
