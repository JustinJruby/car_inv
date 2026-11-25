# Tasks: Car Inventory

**Input**: Design documents from `/specs/001-car-inventory/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Included. Constitution Principle II (Test-Backed Changes) requires tests for every behavior change, even though the spec does not request them explicitly.

**Organization**: Tasks are grouped by user story. Foundational work (sign-in, models) blocks all stories and is done first.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: The user story the task belongs to (US1 to US8)
- Field constraints cite `data-model.md` as `Entity.field`

## Path Conventions

Single Rails application at the repository root, following the default Rails layout (see `plan.md` Project Structure).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Enable the gems and built-in features the plan depends on.

- [x] T001 Uncomment `gem "bcrypt"` in `Gemfile` and run `bundle install`
- [x] T002 Run `bin/rails generate authentication` to create `app/models/user.rb`, `app/models/session.rb`, `app/controllers/sessions_controller.rb`, and `app/controllers/concerns/authentication.rb`, then run `bin/rails db:migrate`
- [x] T003 [P] Run `bin/rails action_text:install` to create the Action Text migrations, `app/views/active_storage/` partials, and the Trix assets in `app/javascript/application.js`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and tables that every story uses. MUST complete before any user story.

- [x] T004 [P] Create migration `db/migrate/*_create_dealerships.rb` with a `name` string column and unique index (data-model.md: Dealership.name)
- [x] T005 Create migration `db/migrate/*_create_cars.rb` with `dealership_id`, `make`, `model`, `year`, `vin`, `mileage`, `asking_price_cents`, `status`, `price_dropped_at`, `contact_name`, `contact_phone`, `contact_email`, and `lock_version` (default 0). Add a partial unique index on `vin` where `status != 2` (data-model.md: Car.vin, Car.year, Car.mileage, Car.asking_price_cents, Car.status, Car.price_dropped_at, Car.lock_version)
- [x] T006 [P] Create migration `db/migrate/*_create_features.rb` with a unique `name` string column (data-model.md: Feature.name)
- [x] T007 [P] Create migration `db/migrate/*_create_car_features.rb` with `car_id` and `feature_id` references and a unique index on `(car_id, feature_id)` (data-model.md: CarFeature)
- [x] T008 Run `bin/rails db:migrate` to apply T004 to T007 and confirm `db/schema.rb` matches data-model.md
- [x] T009 [P] Create `app/models/dealership.rb` with `has_many :cars` and name validation (data-model.md: Dealership.name)
- [x] T010 Create `app/models/car.rb` with `belongs_to :dealership`, `enum :status` (available 0, reserved 1, sold 2), `normalizes :vin`, `has_rich_text :description`, `has_many_attached :photos`, `has_many :car_features` and `:features` through, and `lock_version` optimistic locking. Validate `make` and `model` presence, `year` between 1900 and next calendar year, `vin` exactly 17 letters or digits, `mileage` zero or greater, and `asking_price_cents` greater than zero (data-model.md: Car.make, Car.model, Car.year, Car.vin, Car.mileage, Car.asking_price_cents, Car.status)
- [x] T011 [P] Create `app/models/feature.rb` with `normalizes :name` (lowercase, stripped), `has_many :car_features`, and uniqueness validation (data-model.md: Feature.name)
- [x] T012 [P] Create `app/models/car_feature.rb` with `belongs_to :car, touch: true` and `belongs_to :feature` (data-model.md: CarFeature)
- [x] T013 Add Car scopes in `app/models/car.rb`: `available` (status = available), `stale` (updated_at older than 60 days), `by_make`, `priced_between`, `year_between`, and `with_feature` (depends on T010, T012)
- [x] T014 Add staff-only access in `app/controllers/application_controller.rb` by including the generated `Authentication` concern and requiring sign-in by default. Allow public pages to skip it with `allow_unauthenticated_access`
- [x] T015 [P] Create `db/seeds.rb` with two dealerships, one staff user, and a few cars with features (uses data-model.md entities; no real VINs)
- [x] T016 [P] Create the shared staff and public layouts in `app/views/layouts/application.html.erb` with a navigation bar that shows sign-in or sign-out status

**Checkpoint**: Foundation ready. User stories can now start.

---

## Phase 3: User Story 1 - Staff manage car listings (Priority: P1) MVP

**Goal**: A signed-in staff member can create, edit, and remove listings, with VIN validation.

**Independent Test**: Sign in as staff, create a car with all required fields, edit its price, then remove it (see quickstart.md Scenario 2).

### Tests for User Story 1

- [x] T017 [P] [US1] Create fixtures in `test/fixtures/dealerships.yml`, `test/fixtures/users.yml`, `test/fixtures/cars.yml`, and `test/fixtures/features.yml`
- [x] T018 [P] [US1] Write request tests in `test/controllers/manage/cars_controller_test.rb` for create with valid data, create with a 16-character VIN (rejected), edit price, and destroy
- [x] T019 [P] [US1] Write model tests in `test/models/car_test.rb` for VIN length, VIN normalization to uppercase, year range, and the price greater-than-zero rule (data-model.md: Car.vin, Car.year, Car.asking_price_cents)
- [x] T020 [P] [US1] Write a request test in `test/controllers/sessions_controller_test.rb` that an unauthenticated request to `/manage/cars` redirects to sign-in

### Implementation for User Story 1

- [x] T021 [US1] Add `rate_limit to: 10, within: 3.minutes, only: :create, by: -> { params[:email_address].to_s.downcase }` to `app/controllers/sessions_controller.rb`, and return the same generic error whether or not the email exists (FR-002; data-model.md: User.email_address)
- [x] T022 [US1] Create `app/controllers/manage/cars_controller.rb` with `index`, `new`, `create`, `edit`, `update`, and `destroy`, using `params.expect` for car attributes (data-model.md: Car fields)
- [x] T023 [US1] Add `namespace :manage { resources :cars }` to `config/routes.rb`
- [x] T024 [US1] Create views `app/views/manage/cars/index.html.erb`, `new.html.erb`, `edit.html.erb`, and `_form.html.erb`. The form shows field-level VIN and year errors (data-model.md: Car.vin, Car.year)
- [x] T025 [US1] Add a delete button with confirmation in `app/views/manage/cars/index.html.erb` that calls `destroy`
- [x] T026 [US1] Verify the tests from T018 to T020 pass with `bin/rails test test/controllers test/models`

**Checkpoint**: US1 is complete and independently testable. Staff can manage listings.

---

## Phase 4: User Story 2 - Customers search and filter available cars (Priority: P1)

**Goal**: Customers without an account browse and filter available cars, and reserved or sold cars never appear.

**Independent Test**: Load the public inventory with known cars and apply each filter (see quickstart.md Scenario 5).

### Tests for User Story 2

- [x] T027 [P] [US2] Write request tests in `test/controllers/cars_controller_test.rb` for filtering by make, price range, year, and feature, and for combining filters (FR-012)
- [x] T028 [P] [US2] Write a request test in `test/controllers/cars_controller_test.rb` that reserved and sold cars are excluded from results (FR-013; data-model.md: Car.status)

### Implementation for User Story 2

- [x] T029 [US2] Create `app/controllers/cars_controller.rb` with public `index` and `show` actions. Mark both `allow_unauthenticated_access`. Combine the scopes from T013 based on the query parameters, always starting from `Car.available`
- [x] T030 [US2] Add `resources :cars, only: [:index, :show]` to `config/routes.rb`
- [x] T031 [US2] Create `app/views/cars/index.html.erb` with a GET filter form (make, min and max price, year, feature) wrapped in a `turbo_frame_tag "car_results"`, so filtering doesn't reload the page
- [x] T032 [US2] Create `app/views/cars/_results.html.erb` and show "no cars match" when the filter returns nothing (quickstart.md Scenario 5, step 5)
- [x] T033 [US2] Create `app/views/cars/show.html.erb` with the car's make, model, year, mileage, price, and features. Do not show contact fields (FR-020)

**Checkpoint**: US1 and US2 both work. This is the MVP: staff can list cars and customers can find them.

---

## Phase 5: User Story 3 - Staff see status and price changes live (Priority: P2)

**Goal**: A status or price change appears on other open staff screens within 5 seconds, and conflicting saves are rejected.

**Independent Test**: Open the same car on two staff windows, change status on one, and confirm the other updates (quickstart.md Scenario 4).

### Tests for User Story 3

- [ ] T034 [P] [US3] Write a request test in `test/controllers/manage/cars_controller_test.rb` that a save with a stale `lock_version` is rejected with a reload message (FR-021; data-model.md: Car.lock_version)
- [ ] T035 [P] [US3] Write a system test in `test/system/live_updates_test.rb` with two browser sessions: a status change on one appears on the other without reload (FR-010)

### Implementation for User Story 3

- [ ] T036 [US3] Add `broadcasts_refreshes` to `app/models/car.rb` so changes to a car broadcast a Turbo refresh to subscribers (FR-010)
- [ ] T037 [US3] Add `turbo_stream_from @car` to `app/views/manage/cars/show.html.erb`, and `turbo_stream_from "manage_cars"` to `app/views/manage/cars/index.html.erb`, so open staff pages subscribe to changes
- [ ] T038 [US3] Rescue `ActiveRecord::StaleObjectError` in `app/controllers/manage/cars_controller.rb` `update` and render a "This car was changed. Reload and try again." message (data-model.md: Car.lock_version)
- [ ] T039 [US3] Add `broadcasts_refreshes` and `turbo_stream_from` for the public car page in `app/views/cars/show.html.erb`, so customers see status changes within seconds (SC-003)

**Checkpoint**: Live updates work for staff and customers.

---

## Phase 6: User Story 4 - Photos, descriptions, and features (Priority: P2)

**Goal**: Staff attach photos, write rich-text descriptions, and tag features; customers see all of it.

**Independent Test**: Attach three photos and a formatted description, then view the car as a customer (quickstart.md Scenario 3).

### Tests for User Story 4

- [ ] T040 [P] [US4] Write model tests in `test/models/car_test.rb` for photo content types (JPEG, PNG, WebP only) and photo size limits (data-model.md: Car.photos)
- [ ] T041 [P] [US4] Write a request test in `test/controllers/manage/cars_controller_test.rb` that a failed photo upload keeps previously attached photos (edge case in spec)
- [ ] T042 [P] [US4] Write a system test in `test/system/car_media_test.rb` that a formatted description and a feature tag entered by staff appear on the customer page

### Implementation for User Story 4

- [ ] T043 [US4] Add photo validation to `app/models/car.rb`: allowed content types JPEG, PNG, and WebP, and a per-file size cap (data-model.md: Car.photos)
- [ ] T044 [US4] Permit `photos: []`, `description`, and `feature_names` in `app/controllers/manage/cars_controller.rb`, and wrap attach in a transaction so a failed upload keeps existing photos
- [ ] T045 [US4] Add `feature_names=` to `app/models/car.rb` that finds or creates `Feature` records by normalized name (data-model.md: Feature.name)
- [ ] T046 [US4] Add a rich-text description field and photo upload field to `app/views/manage/cars/_form.html.erb`, and a comma-separated feature tags field
- [ ] T047 [US4] Create `app/views/cars/_gallery.html.erb` that shows photo variants in attachment order (quickstart.md Scenario 3, step 1)
- [ ] T048 [US4] Render the gallery and the rich-text description in `app/views/cars/show.html.erb`

**Checkpoint**: Listings have full media and descriptions.

---

## Phase 7: User Story 5 - Customer favorites without an account (Priority: P2)

**Goal**: Customers save cars as favorites stored in their browser, with no sign-up.

**Independent Test**: Save two cars, reload, confirm they persist; clear browser storage, confirm they are gone (quickstart.md Scenario 6).

### Tests for User Story 5

- [ ] T049 [P] [US5] Write a request test in `test/controllers/favorites_controller_test.rb` that `GET /favorites?ids=` returns the named cars and shows a sold car as unavailable (FR-014, edge case)
- [ ] T050 [P] [US5] Write a system test in `test/system/favorites_test.rb` for save, reload persistence, and clearing storage (FR-015)

### Implementation for User Story 5

- [ ] T051 [US5] Create `app/javascript/controllers/favorites_controller.js` as a Stimulus controller. It saves and removes car IDs in `localStorage` under one key with a try/catch around each read and write (data-model.md: Favorite)
- [ ] T052 [US5] Add a "Save" button to `app/views/cars/show.html.erb` wired to the favorites controller
- [ ] T053 [US5] Create `app/controllers/favorites_controller.rb` with `index` that reads `ids` from the query string, loads those cars including unavailable ones, and marks unavailable cars (FR-014)
- [ ] T054 [US5] Add `get "favorites", to: "favorites#index"` to `config/routes.rb`
- [ ] T055 [US5] Create `app/views/favorites/index.html.erb` that lists the cars and includes a Stimulus target that fills the list from `localStorage` when the page loads

**Checkpoint**: Favorites work without an account.

---

## Phase 8: User Story 6 - Price reduction badge on favorites (Priority: P3)

**Goal**: A price reduction marks each favorite with a "Price dropped" badge on the same device, with no email.

**Independent Test**: Save a car, lower its price as staff, reopen favorites on the same browser (quickstart.md Scenario 7).

### Tests for User Story 6

- [ ] T056 [P] [US6] Write model tests in `test/models/car_test.rb`: `price_dropped_at` is set when `asking_price_cents` decreases, and not when it increases (data-model.md: Car.price_dropped_at, Car.asking_price_cents)
- [ ] T057 [P] [US6] Write a system test in `test/system/price_badge_test.rb` for the badge appearing after a price reduction and disappearing on the next visit

### Implementation for User Story 6

- [ ] T058 [US6] Add a `before_save` callback to `app/models/car.rb` that sets `price_dropped_at` to the current time when `asking_price_cents` decreases (data-model.md: Car.price_dropped_at)
- [ ] T059 [US6] Add `data-favorites-price-dropped-at` attributes to the favorites list in `app/views/favorites/index.html.erb`
- [ ] T060 [US6] Extend `app/javascript/controllers/favorites_controller.js` to compare each favorite's `last_seen_at` with `price_dropped_at`, show the badge when the drop is newer, and update `last_seen_at` after the page renders
- [ ] T061 [US6] Confirm no mailer is called for price changes by adding a test in `test/models/car_test.rb` that a price drop enqueues no mail jobs (FR-016)

**Checkpoint**: Price drops appear as badges, with no email.

---

## Phase 9: User Story 7 - Nightly stale-listing report (Priority: P3)

**Goal**: Staff get a nightly report of listings unchanged for 60 days.

**Independent Test**: Create a car last edited 61 days ago and one edited yesterday, run the job, confirm only the old car appears (quickstart.md Scenario 8).

### Tests for User Story 7

- [ ] T062 [P] [US7] Write model tests in `test/models/car_test.rb` for the `stale` scope: a car 61 days old is included, and a car 59 days old is not (FR-017)
- [ ] T063 [P] [US7] Write a job test in `test/jobs/stale_listing_report_job_test.rb` that the job sends one email per staff member listing the stale cars

### Implementation for User Story 7

- [ ] T064 [US7] Create `app/mailers/staff_mailer.rb` with a `stale_listings(user, cars)` method, sent to `user.email_address` (data-model.md: User.email_address)
- [ ] T065 [US7] Create `app/views/staff_mailer/stale_listings.text.erb` that lists each car's make, model, VIN, and last-edited date
- [ ] T066 [US7] Create `app/jobs/stale_listing_report_job.rb` that loads `Car.stale` and calls `StaffMailer.stale_listings(...).deliver_later` for each staff user
- [ ] T067 [US7] Add a nightly entry for the job to `config/recurring.yml` for Solid Queue
- [ ] T068 [US7] Update `updated_at` on the car when photos are attached or removed, in `app/controllers/manage/cars_controller.rb`, so the stale report counts media edits (FR-017; research.md #11)

**Checkpoint**: The nightly report runs and counts every kind of edit.

---

## Phase 10: User Story 8 - Share a single car via expiring link (Priority: P3)

**Goal**: Staff generate a link to one car that works for 7 days, without contact details.

**Independent Test**: Generate a link, open it, and confirm it stops working after 7 days (quickstart.md Scenario 9).

### Tests for User Story 8

- [ ] T069 [P] [US8] Write a request test in `test/controllers/shares_controller_test.rb` that a valid link shows the car, and an expired link shows "link expired" without car details (FR-018)
- [ ] T070 [P] [US8] Write a request test in `test/controllers/shares_controller_test.rb` that the share page does not show contact name, phone, or email (FR-019)

### Implementation for User Story 8

- [ ] T071 [US8] Add `generates_token_for :share, expires_in: 7.days` to `app/models/car.rb` (research.md #12)
- [ ] T072 [US8] Create `app/controllers/manage/shares_controller.rb` with `create` that returns a share URL for one car (FR-018)
- [ ] T073 [US8] Add `post "share", to: "shares#create"` under `resources :cars` in the manage namespace in `config/routes.rb`
- [ ] T074 [US8] Create `app/controllers/shares_controller.rb` with `show` that resolves the token with `Car.find_by_token_for(:share, params[:token])` and renders "link expired" when it returns nil, and `allow_unauthenticated_access`
- [ ] T075 [US8] Create `app/views/shares/show.html.erb` that shows photos, description, and features, without contact fields (FR-019)

**Checkpoint**: Share links work and never expose contact details.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Performance, security, and end-to-end validation.

- [ ] T076 [P] Add fragment caching with `cache car` in `app/views/cars/_car.html.erb` for car cards in the public results list (SC-004; research.md #13)
- [ ] T077 [P] Write a request test in `test/controllers/contact_privacy_test.rb` that contact fields are absent from the public car page and the share page, and present on staff pages (FR-020)
- [ ] T078 [P] Run `bin/rubocop` and fix reported issues across `app/` and `test/`
- [ ] T079 [P] Run `bin/brakeman` and resolve any findings for this feature
- [ ] T080 Run `bin/ci` and confirm all tests pass
- [ ] T081 Walk through every scenario in `specs/001-car-inventory/quickstart.md` by hand and record any mismatch in `specs/001-car-inventory/quickstart.md` notes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup. Blocks all user stories.
- **User Stories (Phases 3 to 10)**: Each depends only on Foundational. US1 and US2 are both P1 and can run in parallel. US3 to US8 build on US1's listing UI.
- **Polish (Final Phase)**: Depends on all stories you chose to deliver.

### Story Dependencies

- **US1 (P1)**: Needs Foundational only. Blocks US3, US4, US8 (they edit listings).
- **US2 (P1)**: Needs Foundational only. Independent of US1 except for seeded data.
- **US3 (P2)**: Needs US1 (the staff pages it broadcasts to).
- **US4 (P2)**: Needs US1 (the form it extends).
- **US5 (P2)**: Needs US2 (the car pages it adds a Save button to).
- **US6 (P3)**: Needs US5 (the favorites list it badges).
- **US7 (P3)**: Needs US1 (the `updated_at` edits it reports on).
- **US8 (P3)**: Needs US1 (the car it shares).

### Within Each Story

- Tests come first and should fail before implementation.
- Models, then controllers, then routes, then views.

## Parallel Execution Examples

**User Story 1**: T017, T018, T019, T020 are all tests in different files and can run together.

**User Story 2**: T027 and T028 are tests in the same file, so run them in sequence.

**Foundational**: T004, T006, T007, T009, T011, T012, T015, T016 each touch separate files and can run in parallel.

## Implementation Strategy

### MVP First (US1 and US2)

1. Complete Setup and Foundational (Phases 1 and 2).
2. Complete US1 (staff listings) and US2 (customer search), which are both P1.
3. Validate with quickstart.md Scenarios 2 and 5.
4. Stop and review. This is the first deployable increment.

### Incremental Delivery

1. Add US3 and US4 (live updates, media) for a richer staff experience.
2. Add US5 and US6 (favorites and badges) for customer engagement.
3. Add US7 and US8 (nightly report, share links) for the remaining features.
4. Each story is delivered and tested without breaking earlier ones.

---

## Notes

- Every task names its file path, so each can be done without other context.
- Constrained fields cite `data-model.md` as `Entity.field`.
- Tasks marked [P] touch separate files and have no dependency on incomplete tasks.
- Commit after each phase.
