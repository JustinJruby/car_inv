class Manage::SharesController < ApplicationController
  def create
    car = Car.find(params[:car_id])
    url = share_url(token: car.generate_token_for(:share))
    redirect_to edit_manage_car_path(car), notice: "Share link (valid 7 days): #{url}", status: :see_other
  end
end
