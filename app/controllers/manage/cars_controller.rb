class Manage::CarsController < ApplicationController
  before_action :set_car, only: %i[show edit update destroy]

  def index
    @cars = Car.includes(:dealership).order(:make, :model)
  end

  def show
  end

  def new
    @car = Car.new
  end

  def create
    @car = Car.new(car_params)

    if @car.save
      redirect_to manage_cars_path, notice: "Car added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @car.assign_attributes(car_params)
    # Compare against the version the form loaded, so a stale save is rejected (FR-021).
    @car.lock_version = params.dig(:car, :lock_version) if params.dig(:car, :lock_version).present?

    if @car.save
      # Photo changes do not touch the record on their own, so touch it for the stale report (FR-017).
      @car.touch if car_params[:photos].present?
      redirect_to manage_cars_path, notice: "Car updated."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::StaleObjectError
    flash.now[:alert] = "This car was changed by someone else. Reload the page and try again."
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @car.destroy!
    redirect_to manage_cars_path, notice: "Car removed.", status: :see_other
  end

  private
    def set_car
      @car = Car.find(params[:id])
    end

    def car_params
      params.expect(car: [ :dealership_id, :make, :model, :year, :vin, :mileage, :asking_price, :status,
                          :contact_name, :contact_phone, :contact_email, :description, :feature_names,
                          { photos: [] } ])
    end
end
