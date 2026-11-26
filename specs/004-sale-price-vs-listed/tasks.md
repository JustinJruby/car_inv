# Tasks: Sale Price vs Listed Price

**Input**: Design documents from `/specs/004-sale-price-vs-listed/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Included. Constitution Principle II requires tests that fail without the change, and the spec's acceptance scenarios name each behavior.

**Organization**: Tasks are grouped by user story. Foundational work (migrations and the history model) comes first because every story uses it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 (record the sale price, P1), US2 (see the difference, P1), US3 (sales report, P2)

---

## Phase 1: Setup

**Purpose**: Record the starting point before any change.

- [x] T001 Run `bin/rails test` and `bin/rails test:system` on the branch before any change, and record the counts in `specs/004-sale-price-vs-listed/research.md` under a new "Baseline" note

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Columns, the history table, and the history model. No story work starts until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Create migration `db/migrate/<timestamp>_add_sale_fields_to_cars.rb` adding nullable columns to `cars`: `sale_price_cents` (integer), `sold_at` (datetime), `asking_price_at_sale_cents` (integer), `first_listed_price_cents` (integer), `dealer_cost_cents` (integer). Constrained fields per `data-model.md`: `Car.sale_price_cents`, `Car.sold_at`, `Car.asking_price_at_sale_cents`, `Car.first_listed_price_cents`, `Car.dealer_cost_cents`. No defaults, nullable at the database; the model enforces the rules.
- [x] T003 Create migration `db/migrate/<timestamp>_create_car_price_events.rb` for `car_price_events`. Constrained fields per `data-model.md`: `CarPriceEvent.kind` (string, required), `CarPriceEvent.from_cents` (integer, nullable), `CarPriceEvent.to_cents` (integer, nullable). Also `car_id` and `user_id` references (required) and `created_at`. Add foreign keys to `cars` and `users`.
- [x] T004 Create migration `db/migrate/<timestamp>_backfill_first_listed_price.rb` that sets `Car.first_listed_price_cents` to `Car.asking_price_cents` for every existing car where it is nil (research R3). The migration is data-only and reversible as a no-op.
- [x] T005 Run `bin/rails db:migrate` and confirm `db/schema.rb` lists the new columns and the `car_price_events` table.
- [x] T006 [P] Write model tests in `test/models/car_price_event_test.rb` for: `CarPriceEvent.kind` accepts `sold`, `sale_price_corrected`, `sale_price_cleared`, `dealer_cost_set`, and `dealer_cost_changed`, and rejects any other value; `car` and `user` are required.
- [x] T007 [P] Create `app/models/car_price_event.rb`: `belongs_to :car` and `:user`; validation that `CarPriceEvent.kind` is one of the five allowed values from `data-model.md`. `CarPriceEvent.from_cents` and `CarPriceEvent.to_cents` are optional integers.
- [x] T008 Add `has_many :car_price_events, dependent: :destroy` and an `attr_accessor :changed_by` to `app/models/car.rb`. `changed_by` holds the staff member the history rows are written for (set by the controller).

**Checkpoint**: Columns, history table, and history model exist. User story phases can begin.

---

## Phase 3: User Story 1 - Record the selling price when a car is sold (Priority: P1) 🎯 MVP

**Goal**: Staff enter a sale price when marking a car sold. The sale is saved with its snapshot and date, and corrections and dealer cost changes are kept in the history (FR-001, FR-002, FR-003, FR-006, FR-007, FR-011, FR-012).

**Independent Test**: Mark a listed car sold with a price. Confirm the car shows the sale price and date, a `sold` event is recorded, and a sold car with no price cannot be saved.

### Tests for User Story 1

- [x] T009 [P] [US1] Add model tests to `test/models/car_test.rb` for: a sold car requires `Car.sale_price_cents` and rejects zero or negative values (FR-001, FR-002); a sale price with more than two decimal places is rejected; a pre-feature sold car with no `Car.sale_price_cents` cannot be saved for another change (FR-011), and once priced its `Car.asking_price_at_sale_cents` is set so the difference shows; marking a car sold sets `Car.sold_at` and copies `Car.asking_price_at_sale_cents`; a later change to `Car.asking_price_cents` leaves the snapshot and difference unchanged; `Car.first_listed_price_cents` is set once and never changes; `Car.dealer_cost_cents` rejects zero when present.
- [x] T010 [P] [US1] Add controller tests to `test/controllers/manage/cars_controller_test.rb` for: marking a car sold with a price saves it and writes a `sold` event; marking sold with no price is rejected and the car stays unsold; correcting the price writes `sale_price_corrected` with the old and new values; setting dealer cost writes `dealer_cost_set`; changing it writes `dealer_cost_changed`; changing a sold car's status to another status writes `sale_price_cleared` with the old price and clears `Car.sale_price_cents`, `Car.sold_at`, and `Car.asking_price_at_sale_cents` (FR-007).

### Implementation for User Story 1

- [x] T011 [US1] In `app/models/car.rb`, validate that `Car.sale_price_cents` is present and greater than zero whenever the car is `sold` (FR-001, FR-002, FR-011), and that the raw dollar value entered through the setter in T015 has at most two decimal places (a value with more than two decimals is an error, not a rounded value). Validate that `Car.sold_at` and `Car.asking_price_at_sale_cents` are present whenever the car is `sold` and a sale price is set, as `data-model.md` requires. Validate that `Car.dealer_cost_cents` is greater than zero when present (FR-012), and that the raw dollar value entered through the `dealer_cost=` setter in T015 has at most two decimal places. A dealer cost with more than two decimals is an error that is reported to staff, never dropped: if the raw value is present but not converted, the save fails with a message that the dealer cost must be in dollars and cents. These rules apply on every save, so a pre-feature sold car is blocked until it is priced.
- [x] T012 [US1] In `app/models/car.rb`, when the car becomes `sold`, set `Car.sold_at` to the current time and copy `Car.asking_price_cents` to `Car.asking_price_at_sale_cents` (FR-003, FR-004). Also, when a sale price is saved on a sold car whose `Car.asking_price_at_sale_cents` is empty (a pre-feature car, FR-011), set the snapshot from the current `Car.asking_price_cents` and set `Car.sold_at` if it is empty. This is the first-save rule that makes the difference available for pre-feature cars. Set `Car.first_listed_price_cents` from the first asking price the car ever gets, and leave it unchanged after that (FR-010).
- [x] T013 [US1] In `app/models/car.rb`, write `CarPriceEvent` rows in the same transaction as each change: `sold` when the car becomes sold, `sale_price_corrected` when `Car.sale_price_cents` changes on a sold car, `dealer_cost_set` and `dealer_cost_changed` when `Car.dealer_cost_cents` changes. Each row holds the previous and new values in `CarPriceEvent.from_cents` and `CarPriceEvent.to_cents`, and the user from `changed_by`.
- [x] T014 [US1] In `app/models/car.rb`, when a sold car's status changes to any other status, write a `sale_price_cleared` event with the old price in `CarPriceEvent.from_cents`, then clear `Car.sale_price_cents`, `Car.sold_at`, and `Car.asking_price_at_sale_cents` (FR-007, research R6). Note: this depends on the clearing inference in plan.md; if it changes, update this task.
- [x] T015 [US1] In `app/models/car.rb`, add dollar setters `sale_price=` and `dealer_cost=` that do NOT round. Each setter keeps the raw dollar value, as a BigDecimal, in an instance variable (for example `@sale_price_dollars`), and blank values become nil. A `before_validation` callback converts the raw value to `Car.sale_price_cents` or `Car.dealer_cost_cents` only when it has at most two decimal places. A value with more than two decimal places is left unconverted, so the T011 validation rejects it instead of silently rounding it (FR-002, spec edge case).
- [x] T016 [US1] In `app/controllers/manage/cars_controller.rb`, permit `sale_price` and `dealer_cost` in `car_params`. Set `@car.changed_by = Current.user` before saving. Keep the existing stale-save reload message.
- [x] T017 [US1] [P] Update `app/views/manage/cars/_form.html.erb`: add a `sale_price` field in the "Pricing & status" section, labeled "Sale price ($)", shown with a note that it is required when the status is sold. Add a `dealer_cost` field to the staff-only section, labeled "Dealer cost ($)" and marked optional. Keep existing field names and IDs (FR-003).

**Checkpoint**: US1 complete. Staff can mark a car sold with a price, and the history is recorded.

---

## Phase 4: User Story 2 - See the difference between listed and sale price (Priority: P1)

**Goal**: Staff see the asking price at sale, the first listed price, the sale price, and the difference as an amount, a percentage, and a label (FR-004, FR-005).

**Independent Test**: Sell a car listed at $20,000 for $19,000. Confirm the staff page shows $1,000 below listed, or 5.0% below, and a car with no asking price snapshot shows "not available".

### Tests for User Story 2

- [x] T018 [P] [US2] Add model tests to `test/models/car_test.rb` for: `sale_difference_cents` equals sale price minus `Car.asking_price_at_sale_cents`; `sale_difference_percent` is rounded to one decimal place; `sale_difference_label` is "below listed", "above listed", or "equal to listed" by sign; both return nil when `Car.asking_price_at_sale_cents` is missing, and the label is "not available" (research R4).
- [x] T019 [P] [US2] Add a controller test to `test/controllers/manage/cars_controller_test.rb` for the staff car page: it shows the asking price at sale, the first listed price, the sale price, the difference with its label, and the history entries (FR-004, FR-005).

### Implementation for User Story 2

- [x] T020 [US2] In `app/models/car.rb`, add `sale_difference_cents`, `sale_difference_percent`, and `sale_difference_label` as derived methods over `Car.sale_price_cents` and `Car.asking_price_at_sale_cents`. Nothing is stored (research R4, SC-003).
- [x] T021 [US2] [P] Update `app/views/manage/cars/show.html.erb`: show the asking price at sale, the first listed price, the sale price, the sale date, the difference with its percentage and label, the dealer cost, and the `car_price_events` history with the staff name and time. Show "not available" in place of the difference when it is nil (US2-3).

**Checkpoint**: US2 complete. The staff page shows the difference for each sold car.

---

## Phase 5: User Story 3 - Report on sales against listed price (Priority: P2)

**Goal**: Staff see each car sold in a chosen date range, with listed, sale, and difference, plus totals, and a clear message when nothing sold (FR-008).

**Independent Test**: Sell three cars in one week with known prices. Run the report for that week and confirm each row and the totals match. Run it for an empty week and confirm the empty message.

### Tests for User Story 3

- [x] T022 [P] [US3] Create `test/controllers/manage/sales_controller_test.rb` with tests for: a signed-out request redirects to sign-in; cars sold inside the range appear once, and cars sold outside it do not; the totals show total listed at sale, total sold, and total difference; an empty range shows "No sales in this period"; dealer cost does not appear in the report (FR-009).

### Implementation for User Story 3

- [x] T023 [US3] In `config/routes.rb`, add `resources :sales, only: :index` inside the `manage` namespace, so `GET /manage/sales` is available.
- [x] T024 [P] [US3] In `app/models/car.rb`, add a `sold_between(from, to)` scope that selects sold cars whose `Car.sold_at` date falls within the range, inclusive (research R8).
- [x] T025 [US3] Create `app/controllers/manage/sales_controller.rb` with `index`. Parse `from` and `to` as dates, default to the current month when they are missing, and show an error message when they are invalid. Load the rows with `sold_between` and sum the totals in Ruby.
- [x] T026 [US3] [P] Create `app/views/manage/sales/index.html.erb`: a date range form, a table with car, VIN, listed at sale, sale price, difference with label, and sale date, a totals row, and the empty message "No sales in this period".

**Checkpoint**: US3 complete. The sales report works for any date range.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T027 Create `test/controllers/sale_privacy_test.rb`: the public car pages, the car detail page, and the favorites page never show the sale price, the asking price at sale, the first listed price, the dealer cost, or the difference (FR-009, SC-004). It checks the constrained fields `Car.sale_price_cents`, `Car.asking_price_at_sale_cents`, `Car.first_listed_price_cents`, and `Car.dealer_cost_cents` do not render on any customer page.
- [x] T028 Create `test/system/sale_price_test.rb`: a staff member marks a listed car sold with a price in the browser, then sees the difference on the staff page (quickstart section 4).
- [x] T029 Run `bin/rails test` and `bin/rails test:system` and compare the counts with the baseline from T001. Record the final counts in `specs/004-sale-price-vs-listed/research.md`.
- [ ] T030 Walk through `specs/004-sale-price-vs-listed/quickstart.md` on the development server and record any difference from the expected results. This task needs a browser and is left open until it is done.
- [x] T031 Run `bin/ci` and confirm every step passes.
- [x] T032 Compare `db/schema.rb` with `data-model.md`: the five new `cars` columns are nullable, and `car_price_events` matches the `CarPriceEvent` fields.

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** has no dependencies.
- **Phase 2 (Foundational)** depends on Setup and blocks all stories. T002 to T004 run in order, T005 after them, then T006 and T007 in parallel, then T008.
- **US1** depends on Phase 2. Its tests (T009, T010) come before its implementation (T011 to T017).
- **US2** depends on US1: the difference needs the snapshot and sale price that US1 records.
- **US3** depends on US1 for sold cars, and on US2 for the difference column.
- **Final Phase** depends on all stories.

### Inferences this task list depends on

These were made while planning and have not been confirmed by the user (see plan.md). If any changes, update the tasks named:
- The difference uses the asking price at the moment of sale: T012, T018, T020.
- Dealer cost is optional: T011, T015, T017.
- Changing a sold car's status clears the sale price: T014, T028.

## Parallel Opportunities

- T006 and T007 (history model and its test) can run in parallel after T002 to T005.
- T009 and T010 (US1 tests) can run in parallel.
- T017 (form) can run alongside the US1 model work.
- T018 and T019 (US2 tests) can run in parallel.
- T021 (staff detail view) can run alongside T020.
- T022 (US3 test) can run alongside US2 work.
- T024 and T026 can run in parallel with T025.

## Implementation Strategy

### MVP (User Story 1)

1. Complete Phase 1 and Phase 2.
2. Complete US1 (record the sale with its price and history).
3. Stop and check: mark one car sold with a price in the browser.

### Incremental delivery

1. US2: the difference on the staff page.
2. US3: the sales report.
3. Final phase: privacy, system test, `bin/ci`.

## Notes

- Tests for each behavior come before the code that implements it (Principle II).
- Follow the existing `Car` patterns: optimistic locking, dollar setters, and model-level validations.
- No customer page may show the sale price, the snapshot, the first listed price, the dealer cost, or the difference (FR-009). T027 guards this.
