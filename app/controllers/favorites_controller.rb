# Favorites are stored on the server for the visitor's random identifier (spec 006, research R3).
# A car that is sold or no longer available is still shown, as unavailable (existing edge case).
class FavoritesController < ApplicationController
  include Visitor

  allow_unauthenticated_access
  before_action :set_car, only: %i[create destroy]

  # The favorites page: this visitor's active favorites, most recently saved first.
  # Each row is [car id, car, time saved]. The time saved is the baseline for the price-drop badge.
  def index
    @favorites = Favorite.active.where(visitor_id: visitor_id).includes(:car).order(saved_at: :desc)
      .map { |favorite| [ favorite.car_id, favorite.car, favorite.saved_at ] }
  end

  def create
    Favorite.create!(car: @car, visitor_id: visitor_id, saved_at: Time.current) unless saved?
    render json: { saved: true }
  rescue ActiveRecord::RecordNotUnique
    # A concurrent save from the same visitor already created the active favorite.
    render json: { saved: true }
  end

  def destroy
    Favorite.active.where(car: @car, visitor_id: visitor_id).update_all(removed_at: Time.current)
    render json: { saved: false }
  end

  private
    def set_car
      @car = Car.find(params[:car_id])
    end

    def saved?
      Favorite.active.exists?(car: @car, visitor_id: visitor_id)
    end
end
