# Research: Sale Price vs Listed Price

Decisions come from the clarification session (see spec.md Clarifications) or are design choices made while planning. Choices that are inferences rather than answers are marked.

## R1. Where sale values are stored

**Decision**: Sale values are columns on `cars`: `sale_price_cents`, `sold_at`, `asking_price_at_sale_cents`, `first_listed_price_cents`, and `dealer_cost_cents`. Each change to a sale value or the dealer cost also writes a row to `car_price_events`.

**Rationale**: A car has at most one sale at a time, so one row per car is enough. This matches how the car already holds its price, status, and mileage. It also keeps the report a simple query on `cars`.

**Alternatives considered**:
- A separate `sales` table, one row per sale. It would handle a car sold twice without losing the earlier sale. Rejected for now: a car that is sold, reverted, and sold again keeps its earlier values in the history (FR-007), and a separate table adds a second source of truth for the same fact.

## R2. Required sale price (FR-001, FR-002, FR-011)

**Decision**: `Car` validates that `sale_price_cents` is present whenever the car is `sold`, and greater than zero when present. Because the same validation runs on every save, a pre-feature sold car with no sale price cannot be saved for any other change either (FR-011).

**Rationale**: One rule covers new sales and the legacy case, so the behavior the user chose for FR-011 falls out of FR-001 without a special case.

**Alternatives considered**: A separate check only in the sale form. Rejected: it would let other save paths (the status select, the API of models in tests) bypass the rule.

## R3. Listed prices at the time of sale (FR-004, clarification Q1)

**Decision**: When a car is marked sold, the current `asking_price_cents` is copied to `asking_price_at_sale_cents`. The copy is not changed by later asking-price edits. `first_listed_price_cents` is set the first time a car gets an asking price and never changes after that.

**Rationale**: The user chose to show both listed prices side by side (option C). Snapshotting keeps the difference fixed at the sale (edge case: listed price edited after sale).

**Migration backfill**: `first_listed_price_cents` is set to the current `asking_price_cents` for every existing car. The history before this feature is not recoverable, so the current asking price is the best available first price.

**Alternatives considered**: Derive the sold-time asking price from history. Rejected: the history would need a row for every asking-price change, which the app does not record today.

## R4. The difference is computed, not stored (FR-004, FR-005)

**Decision**: `Car#sale_difference_cents` returns `sale_price_cents - asking_price_at_sale_cents`, or nil when either is missing. `Car#sale_difference_percent` returns the difference divided by `asking_price_at_sale_cents`, rounded to one decimal place. The label is "below listed", "above listed", or "equal to listed" from the sign.

**Rationale**: A stored difference could go stale if a snapshot were corrected. Computing it keeps one source of truth (SC-003).

**Missing snapshot**: A sold car with no `asking_price_at_sale_cents` (for example, a car sold before this feature that has just been priced) shows "not available" (US2-3).

## R5. Dealer cost (FR-012, clarification internal price = dealer cost)

**Decision**: `dealer_cost_cents` is an optional column, greater than zero when present. Setting or changing it writes a `dealer_cost_set` or `dealer_cost_changed` event. It is never rendered on customer pages or the sales report.

**Rationale**: The user answered that the internal price is the dealer cost. No margin is computed, since profit calculations are out of scope.

**Inference to confirm**: Dealer cost is optional (FR-012). The clarification did not say whether it is required.

## R6. Clearing the sale on status change (FR-007)

**Decision**: When a sold car's status changes to any other status, `Car` writes a `sale_price_cleared` event with the old value, then sets `sale_price_cents`, `sold_at`, and `asking_price_at_sale_cents` to nil.

**Rationale**: The spec requires the price to leave the car and stay in the history. Clearing the snapshot too means a car that is sold again later gets a fresh snapshot.

## R7. Sale history (FR-006, FR-008 history, SC-006)

**Decision**: `car_price_events` has `car_id`, `user_id`, `kind` (one of `sold`, `sale_price_corrected`, `sale_price_cleared`, `dealer_cost_set`, `dealer_cost_changed`), `from_cents`, `to_cents`, and `created_at`. Rows are written in the same transaction as the change.

**Rationale**: Mirrors `transit_events` from feature 003, so both histories work the same way.

**Alternatives considered**: An audit gem. Rejected under Principle III, as in feature 003.

## R8. Sales report (FR-008, SC-005)

**Decision**: `Manage::SalesController#index` selects cars with `status = sold`, and `sold_at` within the date range (inclusive). Totals are summed in Ruby over the selected rows. The report shows no dealer cost.

**Rationale**: A few thousand cars make an on-read query well under the 3-second target. An aggregate table would add a write path to keep in sync (Principle III).

**Date handling**: `from` and `to` are dates, interpreted in the app's time zone, and `sold_at` is compared by its date.

## R9. Concurrency

**Decision**: Sale changes use the car's existing `lock_version`, the same optimistic locking the car form already uses. A stale save is rejected with the reload message.

**Rationale**: Two staff marking one car sold at once should not both win (research R6 in feature 003 made the same call for transits).

## R10. Customer privacy (FR-009, SC-004)

**Decision**: No customer view renders `sale_price_cents`, `asking_price_at_sale_cents`, `first_listed_price_cents`, `dealer_cost_cents`, or the difference. A privacy test checks the public car pages and the favorites page.

**Rationale**: The feature adds data that must stay internal. A test is the guard against a future view leaking it.

## Implementation notes (004)

**Baseline (T001)**: before any change, `bin/rails test` ran 110 tests (398 assertions) and `bin/rails test:system` ran 7 tests, all passing. One system run showed an intermittent error that did not reproduce on rerun.

**Final**: `bin/rails test` 146 runs, 514 assertions, 0 failures. `bin/rails test:system` 8 runs (plus the car-navigation regression test: 9), 0 failures.

**Changes made during implementation**:
- Arrival of a transit for a sold car no longer saves the car (spec 003 edge case). Saving it would need a sale price (FR-011), and the car does not change on arrival.
- `sold_at` is set only when empty, so a staff-entered sale date is kept.
- Car links inside the inventory's turbo frame break out of the frame (`data-turbo-frame="_top"`). Without this, clicking a car showed "Content missing".
