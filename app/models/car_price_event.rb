# One recorded change to a car's sale or dealer cost (spec 004, FR-006, FR-007, FR-012).
# Append-only history, written in the same transaction as the change it describes.
class CarPriceEvent < ApplicationRecord
  KINDS = %w[sold sale_price_corrected sale_price_cleared dealer_cost_set dealer_cost_changed].freeze

  belongs_to :car
  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
end
