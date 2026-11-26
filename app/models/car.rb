class Car < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTO_BYTES = 10.megabytes

  belongs_to :dealership

  # Status: available (0), reserved (1), sold (2), in_transit (3). Enum also creates the
  # Car.available, Car.reserved, Car.sold, and Car.in_transit scopes.
  enum :status, { available: 0, reserved: 1, sold: 2, in_transit: 3 }

  # Signed share token that expires after 7 days (FR-018). Nothing is stored in the database.
  generates_token_for :share, expires_in: 7.days

  normalizes :vin, with: ->(vin) { vin.strip.upcase }

  has_rich_text :description
  has_many_attached :photos
  has_many :car_features, dependent: :destroy
  has_many :features, through: :car_features
  has_many :transits, dependent: :restrict_with_error
  has_one :open_transit, -> { open }, class_name: "Transit", inverse_of: :car
  has_many :car_price_events, dependent: :destroy

  # The staff member making a change. Sale and dealer cost history rows are written for them (set by the controller).
  attr_accessor :changed_by

  # Live updates (FR-010): any change refreshes the public list, the staff list,
  # and open car pages. Subscribers are declared with turbo_stream_from in the views.
  after_commit :broadcast_changes, on: %i[create update destroy]
  before_save :apply_pending_feature_names
  before_save :record_price_drop, if: :will_save_change_to_asking_price_cents?
  before_save :set_first_listed_price
  before_save :clear_sale_if_no_longer_sold
  before_validation :convert_dollar_inputs
  before_validation :prepare_sale_snapshot
  after_save :record_sale_history

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
  # D1 (option A): a car in transit needs only its intake fields. Mileage is required once the car
  # is pre-sold. Asking price is set on arrival from the pre-sell price (research R3), so it is
  # required only once the car is not in transit.
  validates :mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, unless: :intake_only?
  validates :asking_price_cents, numericality: { only_integer: true, greater_than: 0 }, unless: :in_transit?

  # Sale rules (spec 004). A sold car needs a sale price on every save, which also blocks
  # pre-feature sold cars until they are priced (FR-001, FR-002, FR-011).
  validates :sale_price_cents, presence: true, if: :sold?
  validates :sale_price_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :sold_at, :asking_price_at_sale_cents, presence: true, if: -> { sold? && sale_price_cents.present? }
  validates :dealer_cost_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :dollar_inputs_have_cents
  validate :new_photos_must_be_images
  after_save :attach_new_photos

  # Photos uploaded in a form. They are added to the gallery on save, so existing
  # photos are kept (FR-007). Assigning to `photos` directly would replace them.
  attr_reader :new_photos

  def new_photos=(files)
    @new_photos = Array(files).reject(&:blank?)
  end

  # Staff enter the asking price in dollars; storage is integer cents.
  def asking_price
    asking_price_cents&.fdiv(100)
  end

  def asking_price=(value)
    self.asking_price_cents = value.present? ? (BigDecimal(value.to_s) * 100).round : nil
  rescue ArgumentError
    self.asking_price_cents = nil
  end

  # Sale price and dealer cost are typed in dollars (FR-002, FR-012). The raw entry is kept here and
  # converted to cents only when it has at most two decimal places. Anything else is an error, not a rounded value.
  def sale_price=(value)
    @sale_price_input = value
  end

  def dealer_cost=(value)
    @dealer_cost_input = value
  end

  # Readers for the form: show what was entered (so a rejected entry is not lost), else the stored amount.
  def sale_price
    @sale_price_input.nil? ? sale_price_cents&.fdiv(100) : @sale_price_input
  end

  def dealer_cost
    @dealer_cost_input.nil? ? dealer_cost_cents&.fdiv(100) : @dealer_cost_input
  end

  # Feature tags are typed as a comma-separated list. They are applied on save,
  # so a rejected form does not change the tags.
  def feature_names
    @pending_feature_names&.join(", ") || features.map(&:name).join(", ")
  end

  def feature_names=(value)
    @pending_feature_names = value.to_s.split(",").map { |name| name.strip.downcase }.reject(&:blank?).uniq
  end

  # What customers can see: available cars, plus cars in transit that are live for pre-sell (spec 003, FR-011).
  scope :listed_for_customers, -> {
    where(status: :available).or(
      where(status: :in_transit, id: Transit.open.where(pre_sell: true).where.not(pre_sell_price_cents: nil).select(:car_id))
    )
  }

  # Stale-listing report (FR-017). Cars in transit are not listings yet, so they are excluded (research R10).
  scope :stale, -> { where("cars.updated_at < ?", 60.days.ago).where.not(status: :in_transit) }
  scope :by_make, ->(make) { where("LOWER(cars.make) = ?", make.to_s.downcase) if make.present? }

  # Cars sold within a date range, by the date they were marked sold, inclusive (spec 004, research R8).
  scope :sold_between, ->(from, to) { sold.where(sold_at: from.beginning_of_day..to.end_of_day) }
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

  # True when a customer should see this car as a pre-sell (open transit, pre-sell flag, price set).
  def pre_sell_live?
    in_transit? && open_transit.present? && open_transit.public_pre_sell?
  end

  # The price customers see, in dollars: the pre-sell price for a live pre-sell, otherwise the asking price.
  def customer_price
    pre_sell_live? ? open_transit.pre_sell_price_cents.fdiv(100) : asking_price
  end

  # The difference between the sale price and the asking price at the moment of sale (spec 004, FR-004, FR-005).
  # It is derived, not stored, so it always matches the two prices it comes from.
  def sale_difference_cents
    return nil if sale_price_cents.nil? || asking_price_at_sale_cents.nil?

    sale_price_cents - asking_price_at_sale_cents
  end

  def sale_difference_percent
    return nil if sale_difference_cents.nil?

    (sale_difference_cents * 100.0 / asking_price_at_sale_cents).round(1)
  end

  def sale_difference_label
    return "not available" if sale_difference_cents.nil?
    return "below listed" if sale_difference_cents.negative?
    return "above listed" if sale_difference_cents.positive?

    "equal to listed"
  end

  # An in-transit car with no open pre-sell only needs its intake fields (D1).
  def intake_only?
    in_transit? && !open_transit&.public_pre_sell?
  end

  # Called when the car's transit arrives. A sold car stays sold (spec edge case).
  # Otherwise the car becomes available, and the pre-sell price becomes its asking price.
  def arrive_from_transit!(transit)
    # A sold car has no listing to change, so its arrival is recorded on the transit only (spec 003, edge case).
    # Saving it here would also require a sale price (spec 004, FR-011).
    return if sold?

    self.status = :available
    self.asking_price_cents = transit.pre_sell_price_cents if transit.pre_sell_price_cents.present?
    save!
  end

  private
    def convert_dollar_inputs
      convert_dollar_input(:@sale_price_input, :sale_price_cents)
      convert_dollar_input(:@dealer_cost_input, :dealer_cost_cents)
    end

    def convert_dollar_input(ivar, column)
      raw = instance_variable_get(ivar)
      return if raw.nil?

      self[column] = nil
      return if raw.blank?

      amount = parse_dollars(raw)
      self[column] = (amount * 100).to_i if amount && cents_exact?(amount)
    end

    def dollar_inputs_have_cents
      check_dollar_input(:@sale_price_input, :sale_price)
      check_dollar_input(:@dealer_cost_input, :dealer_cost)
    end

    def check_dollar_input(ivar, attribute)
      raw = instance_variable_get(ivar)
      return if raw.blank?

      amount = parse_dollars(raw)
      if amount.nil?
        errors.add(attribute, "must be a number")
      elsif !cents_exact?(amount)
        errors.add(attribute, "must be in dollars and cents")
      end
    end

    def parse_dollars(raw)
      BigDecimal(raw.to_s)
    rescue ArgumentError
      nil
    end

    # True when a dollar amount has at most two decimal places.
    def cents_exact?(amount)
      (amount * 100) % 1 == 0
    end

    def set_first_listed_price
      self.first_listed_price_cents ||= asking_price_cents
    end

    # Becoming sold copies the current asking price and sets the sale date. A sold car that gets its first
    # sale price (a pre-feature car, FR-011) gets the same snapshot at that moment.
    def prepare_sale_snapshot
      return unless sold?

      if will_save_change_to_status?
        self.sold_at ||= Time.current
        self.asking_price_at_sale_cents = asking_price_cents
      elsif sale_price_cents.present? && asking_price_at_sale_cents.nil?
        self.asking_price_at_sale_cents = asking_price_cents
        self.sold_at ||= Time.current
      end
    end

    # A sold car whose status changes to another status loses its sale. The old price is kept in
    # the history (FR-007).
    def clear_sale_if_no_longer_sold
      return unless status_in_database == "sold" && !sold?

      @sale_cleared_from = sale_price_cents_in_database
      self.sale_price_cents = nil
      self.sold_at = nil
      self.asking_price_at_sale_cents = nil
    end

    def record_sale_history
      if saved_change_to_status? && sold?
        record_price_event("sold", nil, sale_price_cents)
      elsif sold? && saved_change_to_sale_price_cents?
        from, to = saved_change_to_sale_price_cents
        record_price_event("sale_price_corrected", from, to)
      end

      if @sale_cleared_from
        record_price_event("sale_price_cleared", @sale_cleared_from, nil)
        @sale_cleared_from = nil
      end

      if saved_change_to_dealer_cost_cents?
        from, to = saved_change_to_dealer_cost_cents
        record_price_event(from.nil? ? "dealer_cost_set" : "dealer_cost_changed", from, to)
      end
    end

    def record_price_event(kind, from_cents, to_cents)
      car_price_events.create!(user: changed_by, kind: kind, from_cents: from_cents, to_cents: to_cents, created_at: Time.current)
    end

    def new_photos_must_be_images
      Array(new_photos).each do |file|
        errors.add(:photos, "must be JPEG, PNG, or WebP") unless PHOTO_CONTENT_TYPES.include?(file.content_type)
        errors.add(:photos, "must be 10 MB or smaller") if file.size > MAX_PHOTO_BYTES
      end
    end

    def attach_new_photos
      return if new_photos.blank?

      files = new_photos
      @new_photos = nil # cleared first: attach saves the record, which would run this callback again
      photos.attach(files)
    end

    def apply_pending_feature_names
      return if @pending_feature_names.nil?

      self.features = @pending_feature_names.map { |name| Feature.find_or_create_by!(name: name) }
      @pending_feature_names = nil
    end

    # A lower asking price sets price_dropped_at, which drives the favorites badge (FR-016).
    # No email is sent for price changes (Clarification 1, option B).
    def record_price_drop
      return unless persisted?
      return unless asking_price_cents_in_database.present? && asking_price_cents < asking_price_cents_in_database

      self.price_dropped_at = Time.current
    end

    def broadcast_changes
      broadcast_refresh_to("cars")
      broadcast_refresh_to(self)
    end
end
