# Idempotent seed data for development. Safe to run more than once.
# The staff password below is for local development only. Change it before any shared environment.

dealership_a = Dealership.find_or_create_by!(name: "Northside Motors")
dealership_b = Dealership.find_or_create_by!(name: "Riverside Auto")

User.find_or_create_by!(email_address: "staff@example.test") do |user|
  user.password = "development-only-password"
end

%w[AWD leather\ seats sunroof].each { |name| Feature.find_or_create_by!(name: name.downcase) }

[
  { dealership: dealership_a, make: "Toyota", model: "RAV4", year: 2021, vin: "2T3P1RFV8MC123456", mileage: 38_000, asking_price_cents: 2_450_000, features: %w[awd sunroof] },
  { dealership: dealership_a, make: "Honda", model: "Civic", year: 2019, vin: "2HGFC2F69KH123457", mileage: 52_000, asking_price_cents: 1_620_000, features: %w[leather\ seats] },
  { dealership: dealership_b, make: "Subaru", model: "Outback", year: 2020, vin: "4S4BTANC5L3123458", mileage: 44_500, asking_price_cents: 2_180_000, features: %w[awd leather\ seats] }
].each do |attrs|
  feature_names = attrs.delete(:features)
  car = Car.find_or_initialize_by(vin: attrs[:vin]) do |c|
    c.assign_attributes(attrs)
  end
  car.save!
  feature_names.each do |name|
    car.car_features.find_or_create_by!(feature: Feature.find_by!(name: name))
  end
end
