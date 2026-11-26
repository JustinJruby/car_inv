# Attribute Inventory: FR-003 baseline

Source: commit `3835095` (before the Tailwind restyle), `app/views/` excluding mailers and `pwa/`.
Each line is one label, field name, ID, `data-*` attribute, Turbo stream/frame, Stimulus hook, or role found in a view.

## Known exceptions (not restyle changes)

1. **Photo upload field renamed `photos` → `new_photos`** in `app/views/manage/cars/_form.html.erb`. This came from a behavior fix (uploads add to the gallery instead of replacing it, FR-007 edge case). It was in the working tree before the restyle and was committed with it. The controller, model, and `test/controllers/manage/car_media_test.rb` depend on `new_photos`. This needs a spec decision, not a styling change.
2. **Added:** "Car Inventory" brand link in the layout header; `role="alert"` on the staff form error alert; `role="status"`/`role="alert"` on the shared flash partial. Additive only, no existing name or ID was removed.

## Baseline tokens (pre-restyle)

- `app/views/cars/_car.html.erb: link_to "#{car.year} #{car.make} #{car.model}"`
- `app/views/cars/index.html.erb: f.label :feature`
- `app/views/cars/index.html.erb: f.label :make`
- `app/views/cars/index.html.erb: f.label :max_price`
- `app/views/cars/index.html.erb: f.label :max_year`
- `app/views/cars/index.html.erb: f.label :min_price`
- `app/views/cars/index.html.erb: f.label :min_year`
- `app/views/cars/index.html.erb: f.number_field :max_price`
- `app/views/cars/index.html.erb: f.number_field :max_year`
- `app/views/cars/index.html.erb: f.number_field :min_price`
- `app/views/cars/index.html.erb: f.number_field :min_year`
- `app/views/cars/index.html.erb: f.text_field :feature`
- `app/views/cars/index.html.erb: f.text_field :make`
- `app/views/cars/index.html.erb: submit "Search"`
- `app/views/cars/index.html.erb: turbo_frame_tag "car_results"`
- `app/views/cars/index.html.erb: turbo_stream_from "cars"`
- `app/views/cars/show.html.erb: data-action="favorites#toggle"`
- `app/views/cars/show.html.erb: data-controller="favorites"`
- `app/views/cars/show.html.erb: data-favorites-car-id-value="<%= @car.id %>"`
- `app/views/cars/show.html.erb: data-favorites-target="button"`
- `app/views/cars/show.html.erb: link_to "Back to search"`
- `app/views/cars/show.html.erb: turbo_stream_from @car`
- `app/views/favorites/index.html.erb: data-car-id="<%= id %>"`
- `app/views/favorites/index.html.erb: data-controller="favorites-list"`
- `app/views/favorites/index.html.erb: data-favorites-list-target="badge"`
- `app/views/favorites/index.html.erb: data-price-dropped-at="<%= car&.price_dropped_at&.iso8601(3) %>"`
- `app/views/favorites/index.html.erb: link_to "#{car.year} #{car.make} #{car.model}"`
- `app/views/favorites/index.html.erb: link_to "inventory"`
- `app/views/layouts/application.html.erb: button_to "Sign out"`
- `app/views/layouts/application.html.erb: data-turbo-track`
- `app/views/layouts/application.html.erb: link_to "Inventory"`
- `app/views/layouts/application.html.erb: link_to "Manage cars"`
- `app/views/layouts/application.html.erb: link_to "Staff sign in"`
- `app/views/layouts/application.html.erb: name="apple-mobile-web-app-capable"`
- `app/views/layouts/application.html.erb: name="application-name"`
- `app/views/layouts/application.html.erb: name="mobile-web-app-capable"`
- `app/views/layouts/application.html.erb: name="viewport"`
- `app/views/manage/cars/_form.html.erb: f.collection_select :dealership_id`
- `app/views/manage/cars/_form.html.erb: f.email_field :contact_email`
- `app/views/manage/cars/_form.html.erb: f.file_field :photos`
- `app/views/manage/cars/_form.html.erb: f.hidden_field :lock_version`
- `app/views/manage/cars/_form.html.erb: f.label :asking_price`
- `app/views/manage/cars/_form.html.erb: f.label :contact_email`
- `app/views/manage/cars/_form.html.erb: f.label :contact_name`
- `app/views/manage/cars/_form.html.erb: f.label :contact_phone`
- `app/views/manage/cars/_form.html.erb: f.label :dealership_id`
- `app/views/manage/cars/_form.html.erb: f.label :description`
- `app/views/manage/cars/_form.html.erb: f.label :feature_names`
- `app/views/manage/cars/_form.html.erb: f.label :make`
- `app/views/manage/cars/_form.html.erb: f.label :mileage`
- `app/views/manage/cars/_form.html.erb: f.label :model`
- `app/views/manage/cars/_form.html.erb: f.label :photos`
- `app/views/manage/cars/_form.html.erb: f.label :status`
- `app/views/manage/cars/_form.html.erb: f.label :vin`
- `app/views/manage/cars/_form.html.erb: f.label :year`
- `app/views/manage/cars/_form.html.erb: f.number_field :asking_price`
- `app/views/manage/cars/_form.html.erb: f.number_field :mileage`
- `app/views/manage/cars/_form.html.erb: f.number_field :year`
- `app/views/manage/cars/_form.html.erb: f.rich_text_area :description`
- `app/views/manage/cars/_form.html.erb: f.select :status`
- `app/views/manage/cars/_form.html.erb: f.telephone_field :contact_phone`
- `app/views/manage/cars/_form.html.erb: f.text_field :contact_name`
- `app/views/manage/cars/_form.html.erb: f.text_field :feature_names`
- `app/views/manage/cars/_form.html.erb: f.text_field :make`
- `app/views/manage/cars/_form.html.erb: f.text_field :model`
- `app/views/manage/cars/_form.html.erb: f.text_field :vin`
- `app/views/manage/cars/edit.html.erb: button_to "Create 7-day share link"`
- `app/views/manage/cars/edit.html.erb: link_to "Back to cars"`
- `app/views/manage/cars/index.html.erb: button_to "Remove"`
- `app/views/manage/cars/index.html.erb: link_to "Add a car"`
- `app/views/manage/cars/index.html.erb: link_to "Edit"`
- `app/views/manage/cars/index.html.erb: turbo_stream_from "cars"`
- `app/views/manage/cars/new.html.erb: link_to "Back to cars"`
- `app/views/manage/cars/show.html.erb: link_to "Back to cars"`
- `app/views/manage/cars/show.html.erb: link_to "Edit"`
- `app/views/manage/cars/show.html.erb: turbo_stream_from @car`
- `app/views/passwords/edit.html.erb: submit "Save"`
- `app/views/passwords/new.html.erb: submit "Email reset instructions"`
- `app/views/sessions/new.html.erb: link_to "Forgot password?"`
- `app/views/sessions/new.html.erb: submit "Sign in"`
