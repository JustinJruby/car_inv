class CarFeature < ApplicationRecord
  belongs_to :car, touch: true
  belongs_to :feature

  validates :feature_id, uniqueness: { scope: :car_id }
end
