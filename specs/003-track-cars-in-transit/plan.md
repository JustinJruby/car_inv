# Implementation Plan: Track Cars in Transit

**Branch**: `feature/003-track-cars-in-transit` | **Date**: 2026-11-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-track-cars-in-transit/spec.md`

## Summary

Let dealership staff record a car that is on its way, see all open transits for their dealership ordered by expected arrival (overdue ones flagged), and mark transits arrived, cancelled, or rescheduled, with a full history. Staff can also mark a transit for pre-sell with a price; customers then see that car in the public inventory with the price and expected arrival date. The design reuses the existing Car model with a new `in_transit` status, adds a `Transit` record for each trip with a single open transit per car enforced by the database, and adds a `TransitEvent` table for history. No new gems.

Two product decisions were made by the user and are recorded below: **D1** (fields required at intake: option A) and **D2** (customer action on a pre-sell car: option A).

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.4.1

**Primary Dependencies**: Existing stack only (Active Record, Action Controller and View, Turbo, Stimulus, Solid Queue). No new gems.

**Storage**: SQLite (existing database). Two new tables (`transits`, `transit_events`) and one schema change (`cars.status` gains `in_transit`).

**Testing**: Minitest. Model tests for transit rules, controller tests for staff and customer access, and one system test for the pre-sell flow.

**Target Platform**: Web, server-rendered (Hotwire), same as the rest of the app.

**Project Type**: Web application.

**Performance Goals**: The in-transit list and public inventory load in under 2 seconds at the current scale (a few thousand cars, under 10 dealership locations).

**Constraints**:
- FR-009: origin, expected dates, and history never appear on any customer page.
- FR-002 and SC-005: at most one open transit per car, enforced in the database, not only in the app.
- The existing VIN rule stays: 17 characters, unique among cars that are not sold.

**Scale/Scope**: Tens of transits open at a time across all dealerships. Small enough for one database and in-process jobs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Spec Before Code | `spec.md` exists with user stories, requirements, and success criteria. The spec lives in `specs/<feature>/` as Principle I now says (v1.0.1). | PASS |
| II. Test-Backed Changes | Each FR and acceptance scenario has a planned test (see quickstart). The pre-sell flow gets a system test. | PASS |
| III. Simplicity First | No new gems. Transit state is an enum, not a state machine library. History is a plain table, not an audit gem. Overdue is computed, not stored. | PASS |
| IV. Small, Reviewable Changes | Work splits into four phases below, each leaving the app working and tested. | PASS |
| V. Decisions Are Recorded | Each choice with alternatives is in `research.md`. | PASS |

**Decided by the user (2026-11-26)**:
- **D1 (intake fields): A.** Intake needs VIN, make, model, year, origin, and expected arrival. Mileage and asking price are required when the car is arrived or pre-sold.
- **D2 (customer pre-sell action): A.** Customers can see and favorite a pre-sell car. Orders and deposits happen offline with staff. No contact channel is added in this feature.

**Decided by the user (2026-11-26)**:
- **D3 (staff scoping): B.** All staff see and change every dealership's transits in this version. This gap is recorded in the spec's Assumptions. Per-dealership scoping is a follow-up (research R13).

**Result**: No constitution violations. D1 and D2 are resolved, so task generation is unblocked.

## Phases

| Phase | Scope | Exit check |
|-------|-------|------------|
| 1. Data and core rules | `Transit` and `TransitEvent` models and migrations. `Car` gets `in_transit` status and the D1 validations. Open-transit uniqueness in the database. | Model tests pass for uniqueness, state changes, history, pre-sell price rules, and the car validations. |
| 2. Staff transit management | `Manage::TransitsController` with list, record, show, arrive, cancel, reschedule, and pre-sell actions. Overdue flag. | Controller tests for every staff action, including the signed-out case. |
| 3. Customer pre-sell visibility | Public `CarsController` includes live pre-sell cars. `cars/show` shows pre-sell cars. Favorites treat pre-sell cars as available. Origin never rendered. | Controller tests check the customer view does not contain origin, expected date history, or staff contact. System test covers the pre-sell flow. |
| 4. Verification | Stale-listing report excludes in-transit cars. Quickstart run. `bin/ci`. | `bin/ci` passes. Quickstart scenarios pass. |

## Project Structure

### Documentation (this feature)

```text
specs/003-track-cars-in-transit/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Entities, fields, constraints
├── quickstart.md        # End-to-end validation guide
└── checklists/requirements.md
```

No `contracts/` directory. The feature adds staff pages and one public display change, and the existing app has no external API. The route table below is the complete interface.

### Source Code (repository root)

```text
app/models/
├── car.rb                        # CHANGED: in_transit status, D1 validations, stale scope excludes in-transit
├── transit.rb                    # NEW: state, pre-sell rules, overdue, history writes
└── transit_event.rb              # NEW: one history entry

app/controllers/
├── cars_controller.rb            # CHANGED: index and show include live pre-sell cars
├── favorites_controller.rb       # unchanged (already loads any car by id)
└── manage/transits_controller.rb # NEW: staff transit pages

app/views/
├── cars/_car.html.erb            # CHANGED: "Pre-sell" label, price, expected arrival
├── cars/show.html.erb            # CHANGED: pre-sell block, no origin
├── favorites/index.html.erb      # CHANGED: pre-sell cars are not "no longer available"
└── manage/transits/              # NEW: index, new, show, _form

db/migrate/                       # NEW: create_transits, create_transit_events, add in_transit status index
config/routes.rb                  # CHANGED: manage transits routes

test/
├── models/transit_test.rb        # NEW
├── models/transit_event_test.rb  # NEW
├── models/car_test.rb            # CHANGED: in_transit validations
├── controllers/manage/transits_controller_test.rb  # NEW
├── controllers/transit_privacy_test.rb             # NEW: customer pages never show origin
└── system/pre_sell_test.rb       # NEW
```

**Structure Decision**: Single Rails app. Transit logic stays in the `Transit` model, following the existing pattern (`Car` already holds its own rules). No service objects, because nothing here needs them yet.

## Route Surface

| Method | Path | Audience | Purpose |
|--------|------|----------|---------|
| GET | `/manage/transits` | Staff | Open transits for the staff member's dealership, overdue first, then by expected arrival |
| GET | `/manage/transits/new` | Staff | Record a car in transit |
| POST | `/manage/transits` | Staff | Create transit (and the car if new, per D1) |
| GET | `/manage/transits/:id` | Staff | Transit detail with history |
| POST | `/manage/transits/:id/arrive` | Staff | Mark arrived (requires D1 fields if missing) |
| POST | `/manage/transits/:id/cancel` | Staff | Cancel transit |
| PATCH | `/manage/transits/:id/expected_arrival` | Staff | Change expected arrival date |
| PATCH | `/manage/transits/:id/pre_sell` | Staff | Set or change pre-sell flag and price |
| GET | `/cars` and `/cars/:id` | Customers | Existing routes, now include live pre-sell cars |

## Cross-cutting notes

1. **Overdue** is computed from `expected_arrival_on < Date.current` for open transits. It is not stored.
2. **Stale report**: `Car.stale` must exclude `in_transit` cars. Otherwise a long transit would be reported as a stale listing.
3. **Favorites**: a saved pre-sell car stays favoritable. The favorites view currently marks any non-available car as "no longer available", so pre-sell cars need an explicit check.
4. **Live updates**: transit changes do not broadcast in this version. The spec does not require it, and the car broadcast already covers car changes.
5. **Price drops**: lowering a pre-sell price sets `price_dropped_at` on the car, so the existing favorites badge rule applies (spec Assumptions).
