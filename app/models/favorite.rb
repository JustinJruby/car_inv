# A visitor's saved car (spec 006). One row per save; a removal sets removed_at, and saving again
# creates a new row (research R1). visitor_id is a random UUID from the visitor's cookie: the only
# identifier stored (FR-002).
class Favorite < ApplicationRecord
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  belongs_to :car

  scope :active, -> { where(removed_at: nil) }
  scope :saved_within, ->(range) { where(saved_at: range) }

  def active?
    removed_at.nil?
  end

  validates :visitor_id, format: { with: UUID_FORMAT, message: "must be a UUID" }
  validates :saved_at, presence: true
  validate :removed_at_not_before_saved_at
  validates :car_id, uniqueness: { scope: :visitor_id, conditions: -> { where(removed_at: nil) },
    message: "is already a favorite for this visitor" }, if: -> { removed_at.nil? }

  # Staff ranking (spec 006, FR-003, FR-005, FR-006): [car, active favorite count] pairs, most favorited
  # first, ties ordered by make then model. window is "30" (last 30 days) or anything else for all time.
  def self.ranking(window: :all)
    counts = active
    counts = counts.saved_within(30.days.ago..Time.current) if window.to_s == "30"
    counts = counts.group(:car_id).count
    cars = Car.where(id: counts.keys).index_by(&:id)

    counts.map { |car_id, count| [ cars[car_id], count ] }
      .sort_by { |car, count| [ -count, car.make.downcase, car.model.downcase ] }
  end

  private
    def removed_at_not_before_saved_at
      return if removed_at.nil? || saved_at.nil?
      errors.add(:removed_at, "cannot be before the time it was saved") if removed_at < saved_at
    end
end
