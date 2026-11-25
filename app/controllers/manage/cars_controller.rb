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
    if @car.update(car_params)
      redirect_to manage_cars_path, notice: "Car updated."
    else
      render :edit, status: :unprocessable_entity
    end
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
      params.expect(car: %i[dealership_id make model year vin mileage asking_price status
                            contact_name contact_phone contact_email])
    end
end
