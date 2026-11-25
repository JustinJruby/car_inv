class Feature < ApplicationRecord
  normalizes :name, with: ->(name) { name.strip.downcase }

  has_many :car_features, dependent: :destroy
  has_many :cars, through: :car_features

  validates :name, presence: true, uniqueness: true
end
