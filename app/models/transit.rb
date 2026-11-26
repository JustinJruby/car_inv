# One trip of a car to a dealership (spec: Track Cars in Transit).
# Staff record it, reschedule it, set pre-sell, and close it by arrival or cancellation.
# Every change is written to TransitEvent in the same transaction.
class Transit < ApplicationRecord
  # Raised when a change is attempted on an arrived or cancelled transit (final states).
  class NotOpen < StandardError; end

  belongs_to :car
  belongs_to :dealership
  has_many :transit_events, dependent: :destroy

  enum :state, { open: 0, arrived: 1, cancelled: 2 }

  validates :origin, presence: true, length: { maximum: 120 }
  validates :expected_arrival_on, presence: true
  validates :pre_sell_price_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :pre_sell?
  # FR-002: one open transit per car. The database index is the real guarantee (research R5).
  validates :car_id, uniqueness: { conditions: -> { open }, message: "already has an open transit" }, if: :open?
  validate :closed_transits_are_final, on: :update

  def overdue?
    open? && expected_arrival_on < Date.current
  end

  # Customers see a pre-sell car only while its transit is open, marked for pre-sell, and priced.
  def public_pre_sell?
    open? && pre_sell? && pre_sell_price_cents.present?
  end

  def arrive!(user)
    close!(user, "arrived") { car.arrive_from_transit!(self) }
  end

  def cancel!(user)
    close!(user, "cancelled")
  end

  def reschedule!(user, date)
    require_open!
    transaction do
      previous = expected_arrival_on
      update!(expected_arrival_on: date)
      record!(user, "expected_arrival_changed", previous.iso8601, date.iso8601)
    end
  end

  def set_pre_sell!(user, price_cents)
    require_open!
    transaction do
      was_pre_sell = pre_sell?
      previous_price = pre_sell_price_cents
      update!(pre_sell: true, pre_sell_price_cents: price_cents)

      # D1: a pre-sold car needs its mileage on file.
      if car.mileage.nil?
        errors.add(:base, "mileage is required before a car is pre-sold")
        raise ActiveRecord::RecordInvalid, self
      end

      if was_pre_sell
        record!(user, "pre_sell_price_changed", previous_price.to_s, price_cents.to_s)
        # A lower pre-sell price is a price reduction, so the favorites badge applies (spec Assumptions).
        # update_columns skips car validations: the car may not be complete yet, and only this timestamp changes.
        car.update_columns(price_dropped_at: Time.current) if previous_price && price_cents < previous_price
      else
        record!(user, "pre_sell_set", nil, price_cents.to_s)
      end
    end
  end

  private

  def require_open!
    raise NotOpen, "this transit is already #{state}" unless open?
  end

  def close!(user, new_state)
    require_open!
    transaction do
      update!(state: new_state)
      yield if block_given?
      record!(user, new_state, "open", new_state)
    end
  end

  def record!(user, kind, from_value, to_value)
    transit_events.create!(user: user, kind: kind, from_value: from_value, to_value: to_value, created_at: Time.current)
  end

  def closed_transits_are_final
    return if new_record?
    return if state_in_database == "open"
    errors.add(:base, "a #{state_in_database} transit cannot change") if changed?
  end
end
