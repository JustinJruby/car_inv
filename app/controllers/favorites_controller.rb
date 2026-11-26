class FavoritesController < ApplicationController
  allow_unauthenticated_access

  MAX_FAVORITES = 50

  # Favorites are stored in the browser. The page receives the saved ids as ?ids=
  # and looks the cars up here. A car that no longer exists or is not available
  # is shown as unavailable (edge case in the spec).
  def index
    @ids = params[:ids].to_s.split(",").filter_map { |id| Integer(id, exception: false) }.uniq.first(MAX_FAVORITES)
    cars = Car.where(id: @ids).index_by(&:id)
    @favorites = @ids.map { |id| [ id, cars[id] ] }
  end
end
