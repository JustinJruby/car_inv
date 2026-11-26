class Car < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTO_BYTES = 10.megabytes

  belongs_to :dealership

  # Status: available (0), reserved (1), sold (2). Enum also creates the
  # Car.available, Car.reserved, and Car.sold scopes.
  enum :status, { available: 0, reserved: 1, sold: 2 }

  # Signed share token that expires after 7 days (FR-018). Nothing is stored in the database.
  generates_token_for :share, expires_in: 7.days

  normalizes :vin, with: ->(vin) { vin.strip.upcase }

  has_rich_text :description
  has_many_attached :photos
  has_many :car_features, dependent: :destroy
  has_many :features, through: :car_features

  # Live updates (FR-010): any change refreshes the public list, the staff list,
  # and open car pages. Subscribers are declared with turbo_stream_from in the views.
  after_commit :broadcast_changes, on: %i[create update destroy]
  before_save :apply_pending_feature_names
  before_save :record_price_drop, if: :will_save_change_to_asking_price_cents?

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

  # Feature tags are typed as a comma-separated list. They are applied on save,
  # so a rejected form does not change the tags.
  def feature_names
    @pending_feature_names&.join(", ") || features.map(&:name).join(", ")
  end

  def feature_names=(value)
    @pending_feature_names = value.to_s.split(",").map { |name| name.strip.downcase }.reject(&:blank?).uniq
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

  private
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
