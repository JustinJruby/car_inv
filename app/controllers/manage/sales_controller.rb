# Sales report for staff (spec 004, US3). Shows cars sold within a date range against their listed price.
# Dealer cost is never loaded or shown here (FR-012).
class Manage::SalesController < ApplicationController
  def index
    @from = parse_date(params[:from]) || Date.current.beginning_of_month
    @to = parse_date(params[:to]) || Date.current.end_of_month
    @date_error = "Enter valid start and end dates." if invalid_date?(:from) || invalid_date?(:to)

    @cars = @date_error ? [] : Car.sold_between(@from, @to).includes(:dealership).order(:sold_at).to_a
    @totals = totals_for(@cars)
  end

  private
    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def invalid_date?(key)
      params[key].present? && parse_date(params[key]).nil?
    end

    # Totals cover the cars with a difference (a listed price on record). Cars without one are shown in the rows.
    def totals_for(cars)
      measured = cars.select(&:sale_difference_cents)
      {
        listed: measured.sum(&:asking_price_at_sale_cents),
        sold: measured.sum(&:sale_price_cents),
        difference: measured.sum(&:sale_difference_cents),
        count: cars.size
      }
    end
end
