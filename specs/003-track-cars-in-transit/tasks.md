# Tasks: Track Cars in Transit

**Input**: Design documents from `/specs/003-track-cars-in-transit/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Included. Constitution Principle II requires tests that fail without the change, and the spec's acceptance scenarios name each behavior.

**Organization**: Tasks are grouped by user story. Foundational work (migrations and models) comes first because every story uses the transit record.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 (record a car in transit, P1), US2 (see arrivals and overdue, P1), US3 (arrive, cancel, reschedule, P2), US4 (pre-sell, P2)

---

## Phase 1: Setup

**Purpose**: No new project setup is needed. The app, gems, and test suites already exist.

- [x] T001 Confirm `bin/rails test` and `bin/rails test:system` pass on the branch before any change, and record the counts in `specs/003-track-cars-in-transit/research.md` under a new "Baseline" note

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database tables and models that every user story depends on. No story work starts until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Create migration `db/migrate/<timestamp>_create_transits.rb` for the `transits` table. Constrained fields per `data-model.md`: `Transit.origin` (string, 120 characters, required), `Transit.expected_arrival_on` (date, required), `Transit.state` (integer enum, default 0), `Transit.pre_sell` (boolean, default false), `Transit.pre_sell_price_cents` (integer, nullable, required when `Transit.pre_sell` is true), `Transit.lock_version` (integer, default 0). Also `car_id` and `dealership_id` references, and timestamps. Add a partial unique index on `car_id` where `state = 0`, named `index_transits_on_car_id_unless_closed` (the `Transit.state` open rule from `data-model.md`).
- [x] T003 Create migration `db/migrate/<timestamp>_create_transit_events.rb` for `transit_events`. Constrained fields per `data-model.md`: `TransitEvent.kind` (string, required, one of six values), `TransitEvent.from_value` (string, nullable), `TransitEvent.to_value` (string, nullable). Also `transit_id` and `user_id` references and `created_at`. Add foreign keys to `transits` and `users`.
- [x] T004 Run `bin/rails db:migrate` and confirm `db/schema.rb` lists both tables and the partial index.
- [x] T005 [P] Write model tests in `test/models/transit_test.rb` for: origin and expected arrival required; pre-sell requires a price greater than 0; a second open transit for the same car is rejected by the database index and by a validation with a clear message; `arrived` and `cancelled` are final; `overdue?` is true only for open transits with `expected_arrival_on` before `Date.current`; `public_pre_sell?` requires open, pre-sell, and a price.
- [x] T006 [P] Write model tests in `test/models/transit_event_test.rb` for: each `kind` is one of the six allowed values; `user` and `transit` are required; events are written in the same transaction as the change they record.
- [x] T007 Create `app/models/transit.rb` implementing the `data-model.md` Transit rules for `Transit.origin`, `Transit.expected_arrival_on`, `Transit.state`, `Transit.pre_sell`, `Transit.pre_sell_price_cents`, and `Transit.lock_version`: `belongs_to :car` and `:dealership`; `has_many :transit_events`; `enum :state, { open: 0, arrived: 1, cancelled: 2 }`; validations from T005; `overdue?` and `public_pre_sell?`; methods `arrive!(user)`, `cancel!(user)`, `reschedule!(user, date)`, `set_pre_sell!(user, price_cents)`, each writing a `TransitEvent` in the same transaction and raising if the transit is no longer open.
- [x] T008 [P] Create `app/models/transit_event.rb` implementing `TransitEvent.kind` from `data-model.md` (plus `TransitEvent.from_value` and `TransitEvent.to_value` as optional strings): `belongs_to :transit` and `:user`; validation that `kind` is one of `recorded`, `expected_arrival_changed`, `pre_sell_set`, `pre_sell_price_changed`, `arrived`, `cancelled`.
- [x] T009 Add `in_transit` (value 3) to the `Car.status` enum in `app/models/car.rb` (`data-model.md` Car, `Car.status`: available 0, reserved 1, sold 2, in_transit 3), plus `has_many :transits` and `has_one :open_transit`, scoped to `state: :open`.
- [x] T010 Change the car validations in `app/models/car.rb` so `Car.mileage` and `Car.asking_price_cents` are required unless the car is intake-only, per `data-model.md` Car (D1 option A). Keep `Car.vin` unchanged. Define `intake_only?` as `in_transit?` with no open pre-sell transit. Keep the VIN rule unchanged.
- [x] T011 Exclude `in_transit` cars from the `stale` scope in `app/models/car.rb` (research R10).
- [x] T012 [P] Add tests to `test/models/car_test.rb` for: an in-transit car saves without mileage or price; a car with a live pre-sell transit requires them; `Car.stale` excludes in-transit cars.

**Checkpoint**: Models and tables are ready. User story phases can begin.

---

## Phase 3: User Story 1 - Record a car on its way (Priority: P1) 🎯 MVP

**Goal**: Staff can record an inbound car with VIN, make, model, year, origin, and expected arrival date (FR-001, spec US1).

**Independent Test**: As a signed-in staff member, record a car in transit. Confirm it appears in the transit list. Confirm a second open transit for the same VIN is rejected, and that missing origin or date shows a clear error.

### Tests for User Story 1

- [x] T013 [P] [US1] Write controller tests in `test/controllers/manage/transits_controller_test.rb` for: a signed-in staff member records a transit and the car is created with status `in_transit`; a second open transit for the same VIN is rejected with the message "a transit is already open for that car"; a missing origin or expected arrival date is rejected and the message names the field; recording a car whose VIN belongs to a non-sold car is rejected with the message "a car with this VIN is already in inventory or in transit"; a signed-out request redirects to sign-in.

### Implementation for User Story 1

- [x] T014 [US1] Add routes in `config/routes.rb` under the `manage` namespace: `resources :transits, only: %i[index new create show]` with member routes `post :arrive`, `post :cancel`, `patch :expected_arrival`, and `patch :pre_sell`.
- [x] T015 [US1] Create `app/controllers/manage/transits_controller.rb` with `new` and `create`. `create` builds a `Car` with status `in_transit` from the VIN, make, model, year, and dealership and rejects the request with the message "a car with this VIN is already in inventory or in transit" when a non-sold car with that VIN exists (a sold car's VIN may be reused); otherwise it builds the `Transit` with origin and expected arrival; it writes a `recorded` event; both save in one transaction.
- [x] T016 [P] [US1] Create `app/views/manage/transits/new.html.erb` and `app/views/manage/transits/_form.html.erb` with labeled fields (VIN, make, model, year, origin, expected arrival date), `.input` and `.label` classes, and validation errors in an alert above the form.

**Checkpoint**: US1 complete. Staff can record a car in transit.

---

## Phase 4: User Story 2 - See what is arriving and what is late (Priority: P1)

**Goal**: The in-transit list shows open transits by expected arrival date, flags overdue ones, and has an empty state (spec US2).

**Independent Test**: Record three transits with different expected dates, one in the past. Open the list and confirm the order and the overdue flag. With none recorded, confirm the empty message.

### Tests for User Story 2

- [x] T017 [P] [US2] Add tests to `test/controllers/manage/transits_controller_test.rb` for: the index lists open transits ordered by `expected_arrival_on` earliest first; overdue transits show the overdue flag; the empty state text "No cars are in transit" appears when there are none; arrived and cancelled transits are not listed.

### Implementation for User Story 2

- [x] T018 [US2] Add the `index` action to `app/controllers/manage/transits_controller.rb`: open transits, ordered by `expected_arrival_on` ascending, with the car and dealership included to avoid N+1 queries.
- [x] T019 [P] [US2] Create `app/views/manage/transits/index.html.erb` with a styled table or card list, an overdue badge using `.badge`, and the empty state text.
- [x] T020 [US2] Record the D3 decision in the index's code comment: `app/controllers/manage/transits_controller.rb` lists open transits for every dealership, because staff are not linked to a dealership yet (D3 option B, spec Assumptions). Do not add dealership scoping in this feature.

**Checkpoint**: US2 complete, except T020 which is blocked on the dealership decision.

---

## Phase 5: User Story 3 - Mark arrivals, cancellations, and date changes (Priority: P2)

**Goal**: Staff can mark a transit arrived, cancel it, or change its expected date. Each change is recorded in history (spec US3, FR-005 to FR-008).

**Independent Test**: Record a transit, change its date, mark it arrived, and confirm the car is in inventory and the transit is gone from the list. Confirm the history shows each change with the staff member and time.

### Tests for User Story 3

- [x] T021 [P] [US3] Add tests to `test/controllers/manage/transits_controller_test.rb` for: arrive sets the transit to `arrived`, sets the car to `available`, copies the pre-sell price to the car's asking price when present, and writes an `arrived` event; cancel leaves the car's attributes unchanged and writes a `cancelled` event; changing the expected date writes an `expected_arrival_changed` event with the old and new dates; arrived and cancelled transits reject further changes; arriving a transit for a car already marked `sold` leaves the car `sold` and still writes an `arrived` event.
- [x] T022 [P] [US3] Add a concurrency test to `test/controllers/manage/transits_controller_test.rb`: two arrive requests with the same stale `lock_version` produce one success and one stale-object message asking staff to reload (research R6).

### Implementation for User Story 3

- [x] T023 [US3] Add `arrive`, `cancel`, and `expected_arrival` actions to `app/controllers/manage/transits_controller.rb`, calling the model methods from T007 and rescuing `ActiveRecord::StaleObjectError` with the reload message. In the arrival path, set the car to `available` only when its status is not `sold`.
- [x] T024 [US3] In `arrive`, when the car is missing mileage or asking price (`Car.mileage` and `Car.asking_price_cents` per `data-model.md`, D1 option A), require them in the request and update the car in the same transaction before marking it available.
- [x] T025 [P] [US3] Create `app/views/manage/transits/show.html.erb` with the car's details, the origin, the expected arrival date, action buttons for arrive, cancel, and changing the date, and the history list showing each event's kind, values, staff name, and time.

**Checkpoint**: US3 complete.

---

## Phase 6: User Story 4 - Pre-sell a car that is still in transit (Priority: P2)

**Goal**: Staff can mark a transit for pre-sell with a price. Customers see the car with its price, expected arrival, and a pre-sell label. The origin is never shown (spec US4, FR-011 to FR-015, FR-009).

**Independent Test**: Mark an in-transit car for pre-sell with a price. Sign out and confirm `/cars` shows it with the price and label and no origin. Mark it arrived and confirm it is an ordinary available car at the pre-sell price.

### Tests for User Story 4

- [x] T026 [P] [US4] Add tests to `test/controllers/manage/transits_controller_test.rb` for: pre-sell without a price is rejected; setting pre-sell writes a `pre_sell_set` event; changing the price writes a `pre_sell_price_changed` event; lowering the pre-sell price sets `price_dropped_at` on the car (spec Assumptions).
- [x] T027 [P] [US4] Add tests to `test/controllers/cars_controller_test.rb` for: `/cars` includes a pre-sell car with a price and excludes a transit without a price or not marked for pre-sell (SC-007); `/cars/:id` shows a pre-sell car; cancelling the transit removes it from `/cars` (FR-015).
- [x] T028 [P] [US4] Create `test/controllers/transit_privacy_test.rb`: customer pages (`/cars`, `/cars/:id`, `/favorites`) never include the origin, expected-date history, transit events, or staff contact details (FR-009).

### Implementation for User Story 4

- [x] T029 [US4] Add the `pre_sell` action to `app/controllers/manage/transits_controller.rb` calling `set_pre_sell!` from T007, and setting `price_dropped_at` on the car when the price is lowered.
- [x] T030 [US4] Add a public scope to `app/models/car.rb` that returns available cars plus in-transit cars with a live pre-sell transit (`public_pre_sell?`). Use it in `app/controllers/cars_controller.rb` for `index`, and let `show` find pre-sell cars as well as available ones.
- [x] T031 [P] [US4] Update `app/views/cars/_car.html.erb` to show a "Pre-sell" label, the pre-sell price, and the expected arrival date for in-transit cars. Do not show the origin.
- [x] T032 [P] [US4] Update `app/views/cars/show.html.erb` to show a pre-sell block with the price and expected arrival date for in-transit cars. Do not show the origin.
- [x] T033 [US4] Update `app/views/favorites/index.html.erb` so a saved pre-sell car is not labeled "no longer available" (the view currently treats any non-available car that way).
- [x] T034 [P] [US4] Add a system test in `test/system/pre_sell_test.rb` for the independent test above: staff set pre-sell, a signed-out customer sees the car in `/cars`, and after arrival the car shows as a normal listing.

**Checkpoint**: US4 complete.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T035 Confirm the stale-listing report tests in `test/jobs/stale_listing_report_job_test.rb` still pass and that in-transit cars are excluded from it (research R10)
- [x] T036 Run `bin/rails test` and `bin/rails test:system` and confirm both pass, with the counts recorded against the baseline from T001
- [ ] T037 Walk through `quickstart.md` section 4 on the development server and record any differences from the expected results
- [x] T038 [P] Check that the `db/schema.rb` changes match `data-model.md` exactly, including the partial index
- [x] T039 Run `bin/ci` and confirm every step passes

---

## Dependencies & Execution Order

- **Phase 2 (Foundational)** blocks all user stories. T002 before T003, T004 after both, and models (T007 to T012) after the migrations.
- **US1** starts after Phase 2. Its tests (T013) come before its implementation.
- **US2** depends on US1's controller (T015). T020 is blocked (see below).
- **US3** depends on US1 and US2 (the list and detail routes).
- **US4** depends on US3 (`pre_sell` uses the same transit controller and model methods).
- **Polish** depends on all stories.

### Decisions recorded

- **D3 (staff scoping): B.** Every staff member sees every dealership's transits in this version. T020 records this in code. No task is blocked.

## Parallel Opportunities

- T005 and T006 (model tests) can run in parallel after T002 and T003.
- T008 and T012 can run in parallel with T007 and T009.
- Within a story, the test task and the view task marked [P] can run in parallel with the controller task.
- T031 and T032 (customer views) can run in parallel.

## Implementation Strategy

### MVP (User Story 1 and 2)

1. Complete Phase 2 (foundational models and migrations).
2. Complete US1 (record a car in transit) and US2 (the list), resolving T020 first.
3. Stop and validate with quickstart section 2.

### Incremental delivery

1. US3: arrivals, cancellations, reschedules, with history.
2. US4: pre-sell and customer visibility.
3. Polish and `bin/ci`.

## Notes

- Tests for each behavior come before the code that implements it (Principle II).
- Follow the `Car` model's existing patterns: optimistic locking, `after_commit` broadcasts, and validations in the model.
- No customer page may show origin, expected dates, history, or staff contact (FR-009). T028 is the guard.
