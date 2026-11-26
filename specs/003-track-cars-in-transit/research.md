# Research: Track Cars in Transit

Each decision has a rationale and the alternatives considered. D1 and D2 are product decisions and are still open (see plan.md).

## R1. How an in-transit car is represented

**Decision**: An in-transit car is a `Car` record with a new status `in_transit` (enum value 3). A `Transit` record links the car to its trip.

**Rationale**: Customers, favorites, pre-sell listings, and the VIN rule all work on `Car` already. Keeping the car as one record means arrival changes its status rather than creating a second record. The spec's "the car's own details do not change in transit" maps to "only its status and price change on arrival".

**Alternatives considered**:
- A transit-only record that holds the VIN and no `Car`. Rejected: pre-sell, favorites, and the VIN uniqueness rule would each need a second code path.
- Create the `Car` only on arrival. Rejected: pre-sell needs a car to list before it arrives.

## R2. Fields required at intake (D1, open)

**Decision (proposed)**: At intake, require VIN, make, model, year, origin, and expected arrival. Require mileage and asking price only when the car is arrived or pre-sold.

**Rationale**: The current `Car` model requires mileage and asking price on every save (`app/models/car.rb:38-39`). The spec's intake step does not ask for them. Making them conditional on status keeps intake quick, matching SC-001, without weakening the rules for listed cars.

**Alternatives considered**:
- Require all car details at intake. Simpler code, and no conditional validations, but staff must know mileage and price before the car is on the lot.
- Store placeholder values. Rejected: placeholders would show up in reports and listings.

**Status**: Decided by the user (option A, 2026-11-26).

## R3. Where the pre-sell price lives

**Decision**: The pre-sell price is stored on the `Transit`. On arrival it is copied to the car's `asking_price_cents`.

**Rationale**: The spec says the car's details do not change while it is in transit. Holding the pre-sell price on the transit keeps the car record unchanged until arrival, which also keeps the stale-listing report and the car's own history clean.

**Alternatives considered**: Set `asking_price_cents` on the car during transit. Rejected because it changes the car record before arrival, which the spec forbids.

## R4. How pre-sell cars become visible to customers

**Decision**: The public inventory query adds cars that are `in_transit`, have an open transit with `pre_sell` true, and a pre-sell price. Customer views show a "Pre-sell" label. The origin is never selected for customer pages.

**Rationale**: One query scope keeps the existing `Car.available` behavior unchanged and makes the visibility rule (SC-007) testable in one place.

**Alternatives considered**: Add a `pre_sell` status to `Car`. Rejected: pre-sell depends on the transit (it has a price, a date, and an open state), so putting it on the car would duplicate state.

## R5. One open transit per car

**Decision**: A partial unique index on `transits(car_id)` where `state = open`, plus a model validation that gives a clear error message.

**Rationale**: FR-002 and SC-005 require the rule to hold under concurrent requests. Only the database index can guarantee that. The model validation is for the message. The existing VIN index already uses a partial index (`index_cars_on_vin_unless_sold`), so this follows an existing pattern.

**Alternatives considered**: An application-level check alone. Rejected because two requests can both pass the check before either writes.

## R6. Concurrent arrival and edits

**Decision**: `transits` has a `lock_version` column, the same optimistic locking the cars table already uses. Two staff marking the same transit arrived results in one success and one stale-object error that asks staff to reload.

**Rationale**: Matches the spec's edge case and the existing `Manage::CarsController` pattern.

**Alternatives considered**: Row locks. Rejected because the existing app uses optimistic locking everywhere, and consistency matters more than blocking.

## R7. Transit history

**Decision**: A `transit_events` table with one row per change (`recorded`, `expected_arrival_changed`, `pre_sell_set`, `pre_sell_price_changed`, `arrived`, `cancelled`). Each row stores the user, the previous and new values, and the time. Rows are written in the same transaction as the change.

**Rationale**: FR-008 needs a history with the staff member and time. A table is a few lines of code and needs no gem.

**Alternatives considered**: An audit gem such as paper_trail. Rejected under Principle III: it is a new dependency for one table, and the spec asks for a simple history.

## R8. Overdue

**Decision**: Computed on read: an open transit with `expected_arrival_on < Date.current` is overdue. Nothing is stored.

**Rationale**: Overdue depends on today's date, so a stored flag would go stale. Computing it avoids a scheduled job.

**Alternatives considered**: A nightly job that sets a flag. Rejected: it adds a recurring job for no benefit.

## R9. Customer action on a pre-sell car (D2, open)

**Decision (proposed)**: In this feature, customers can see a pre-sell car, its price, and its expected arrival, and can save it as a favorite. Buying, ordering, or paying a deposit happens offline with staff.

**Rationale**: The spec puts payment and checkout out of scope. The app has no customer contact channel today, and staff contact details must stay hidden (FR-020).

**Alternatives considered**:
- A dealership-level phone or email shown on the pre-sell listing. This is new data and needs a privacy review, since the app currently hides contact details.
- An online deposit. Out of scope per the spec.

**Status**: Decided by the user (option A, 2026-11-26).

## R10. Stale-listing report

**Decision**: `Car.stale` excludes `in_transit` cars.

**Rationale**: A car that has been in transit for 60 days is not a stale listing, since nothing is listed yet. Without the exclusion, the nightly report would flag every long transit.

## R11. Routes and interfaces

**Decision**: Staff routes under `/manage/transits`, with member actions for arrive, cancel, expected arrival, and pre-sell. No API and no `contracts/` directory.

**Rationale**: The app has no external interface. Routes follow the existing `manage` namespace.

## R13. Scoping staff to their dealership (D3, decided: B)

**Decision**: All signed-in staff see and change transits for every dealership in this version. The gap is recorded in the spec's Assumptions.

**Rationale**: The `users` table has no dealership link (`db/schema.rb`, `app/models/user.rb`), and the user chose not to add one in this feature. Adding it would need a migration and a way to assign existing users, which is a separate piece of work.

**Alternative not taken**: Add a `dealership_id` to users and scope every staff transit action to it. This is the follow-up.

## R12. Live updates for transits

**Decision**: Not in this version.

**Rationale**: The spec has no live-update requirement for transits. Car changes already broadcast, so a pre-sell price change reaches customers through the car's existing refresh path.

## Implementation notes (2026-11-26)

**Baseline (T001)**: before any change, `bin/rails test` ran 68 tests (228 assertions) and `bin/rails test:system` ran 6 tests (22 assertions), all passing.

**Deviations from the design, to confirm**:
- **Pre-sell requires mileage, asking price does not (D1 detail).** Mileage is required on the car once it is pre-sold, as D1 says. The asking price is set from the pre-sell price on arrival (R3), so a pre-sold car in transit has no asking price yet. Enforced in `Transit#set_pre_sell!` and in `Car`'s `intake_only?` rule.
- **Intake columns are nullable (migration `20261126200003`).** `cars.mileage` and `cars.asking_price_cents` had `NOT NULL`, and mileage defaulted to 0, which would store a fake mileage on intake. Both are nullable now, and the default is removed. Listed cars still require both through model validations.
- **Pre-sell price drop sets `price_dropped_at` with `update_columns`.** The car may be incomplete while in transit, so the validations are skipped for this one timestamp.
- **Customer card cache includes the open transit.** A pre-sell price change must reach customers (FR-013), so the card's cache key includes the transit, not just the car.
- **Price filters exclude pre-sell cars.** The price filter reads the asking price, which is empty until arrival. A customer filtering by price will not see pre-sell cars. Known limitation.
- **Test order.** The car model tests (T012) were written after the `Car` changes they cover, which goes against the "tests before code" note in `tasks.md`.
