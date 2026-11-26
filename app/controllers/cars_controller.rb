class CarsController < ApplicationController
  allow_unauthenticated_access

  def index
    @cars = filtered_cars
  end

  def show
    @car = Car.listed_for_customers.find(params[:id])
  end

  private
    # Customers only see available cars (FR-013) and cars in transit that are live for pre-sell (spec 003).
    # Filters narrow that set. A price filter uses the asking price, so pre-sell cars drop out of it.
    def filtered_cars
      filters = params.permit(:make, :min_price, :max_price, :min_year, :max_year, :feature)

      Car.listed_for_customers
        .includes(:features)
        .by_make(filters[:make])
        .priced_between(filters[:min_price], filters[:max_price])
        .year_between(filters[:min_year], filters[:max_year])
        .with_feature(filters[:feature])
        .order(:make, :model)
    end
end
