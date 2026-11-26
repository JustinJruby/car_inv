# One recorded change to a Transit. Append-only history (spec FR-008).
class TransitEvent < ApplicationRecord
  KINDS = %w[recorded expected_arrival_changed pre_sell_set pre_sell_price_changed arrived cancelled].freeze

  belongs_to :transit
  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
end
