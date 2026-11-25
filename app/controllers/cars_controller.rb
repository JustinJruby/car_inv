class CarsController < ApplicationController
  allow_unauthenticated_access

  def index
    @cars = filtered_cars
  end

  def show
    @car = Car.available.find(params[:id])
  end

  private
    # Customers only ever see available cars (FR-013). Filters narrow that set.
    def filtered_cars
      filters = params.permit(:make, :min_price, :max_price, :min_year, :max_year, :feature)

      Car.available
        .includes(:features)
        .by_make(filters[:make])
        .priced_between(filters[:min_price], filters[:max_price])
        .year_between(filters[:min_year], filters[:max_year])
        .with_feature(filters[:feature])
        .order(:make, :model)
    end
end
