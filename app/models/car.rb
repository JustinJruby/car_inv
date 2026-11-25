class Car < ApplicationRecord
  belongs_to :dealership

  # Status: available (0), reserved (1), sold (2). Enum also creates the
  # Car.available, Car.reserved, and Car.sold scopes.
  enum :status, { available: 0, reserved: 1, sold: 2 }

  normalizes :vin, with: ->(vin) { vin.strip.upcase }

  has_rich_text :description
  has_many_attached :photos
  has_many :car_features, dependent: :destroy
  has_many :features, through: :car_features

  validates :make, :model, presence: true
  validates :year, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1900,
    less_than_or_equal_to: -> { Date.current.year + 1 }
  }
  validates :vin, format: { with: /\A[A-Z0-9]{17}\z/, message: "must be exactly 17 letters or digits" }
  validates :vin, uniqueness: {
    conditions: -> { where.not(status: :sold) },
    message: "is already used by another active listing"
  }, unless: :sold?
  validates :mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :asking_price_cents, numericality: { only_integer: true, greater_than: 0 }

  # Customer-facing: only cars marked available. Enum provides Car.available.
  # Staff enter the asking price in dollars; storage is integer cents.
  def asking_price
    asking_price_cents&.fdiv(100)
  end

  def asking_price=(value)
    self.asking_price_cents = value.present? ? (BigDecimal(value.to_s) * 100).round : nil
  rescue ArgumentError
    self.asking_price_cents = nil
  end

  scope :stale, -> { where("cars.updated_at < ?", 60.days.ago) }
  scope :by_make, ->(make) { where("LOWER(cars.make) = ?", make.to_s.downcase) if make.present? }
  scope :priced_between, ->(min, max) {
    scoped = all
    scoped = scoped.where(asking_price_cents: (min.to_i * 100)..) if min.present?
    scoped = scoped.where(asking_price_cents: ..(max.to_i * 100)) if max.present?
    scoped
  }
  scope :year_between, ->(min, max) {
    scoped = all
    scoped = scoped.where(year: min.to_i..) if min.present?
    scoped = scoped.where(year: ..max.to_i) if max.present?
    scoped
  }
  scope :with_feature, ->(name) {
    where(id: CarFeature.joins(:feature).where(features: { name: name.to_s.strip.downcase }).select(:car_id)) if name.present?
  }
end
