# Staff ranking of cars by active favorites (spec 006, US1). Customers never see this page (FR-004).
class Manage::PopularityController < ApplicationController
  def index
    @window = params[:window] == "30" ? "30" : "all"
    @ranking = Favorite.ranking(window: @window)
  end
end
