# Implementation Plan: Sale Price vs Listed Price

**Branch**: `feature/004-sale-price-vs-listed` | **Date**: 2026-11-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-sale-price-vs-listed/spec.md`

## Summary

Staff record the price a car sold for when they mark it sold. Each sold car shows its asking price at the moment of sale, its first listed price, its sale price, and the difference against the asking price at sale (amount and percentage). Staff can also record the dealer's cost for a car, which is never shown to customers. A staff-only report lists sales in a date range with totals. Sale price and dealer cost changes are kept in a history. The design adds columns to `cars` and one history table, with no new gems. The sale rules live in the `Car` model, so the same rule applies to new sales and to pre-feature sold cars (FR-001 and FR-011).

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.4.1

**Primary Dependencies**: Existing stack only (Active Record, Action Controller and View, Turbo). No new gems.

**Storage**: SQLite. Five new `cars` columns, one new history table (`car_price_events`).

**Testing**: Minitest. Model tests for the sale rules, controller tests for the sale form and report, one system test for the sale flow, and privacy tests for customer pages.

**Target Platform**: Web, server-rendered (Hotwire), same as the rest of the app.

**Project Type**: Web application.

**Performance Goals**: The sales report for a one-month range loads in under 3 seconds (SC-005) at a few thousand cars.

**Constraints**:
- FR-009 and SC-004: sale prices, dealer costs, differences, and the report never appear on customer pages.
- FR-002: a sale price is greater than zero, with at most two decimal places (stored as integer cents).
- FR-011: until a pre-feature sold car has a sale price, no other change to it can be saved.

**Scale/Scope**: A few thousand cars, under 10 dealership locations, a handful of staff per location.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Spec Before Code | `spec.md` exists in `specs/004-sale-price-vs-listed/` with clarifications recorded. Principle I (v1.0.1) places specs there. | PASS |
| II. Test-Backed Changes | Each FR and acceptance scenario has a planned test (see quickstart). The sale rule and the report get model and controller tests. | PASS |
| III. Simplicity First | No new gems. Sale and cost values are columns on `cars`, since a car has at most one sale at a time. One history table, as in feature 003. No aggregation tables: the report computes totals on read. | PASS |
| IV. Small, Reviewable Changes | Work splits into five phases below, each leaving the app working and tested. | PASS |
| V. Decisions Are Recorded | Each choice with alternatives is in `research.md`. | PASS |

**Open decisions**: none. Every clarification from the session is recorded in the spec.

**Inferences to confirm before tasks** (made while planning, not asked in the session):
- The difference is measured against the asking price at the moment of sale (spec Clarifications, FR-004).
- Dealer cost is optional (FR-012).
- A car that is marked sold stops being `sold` if its status changes, and its sale price moves to the history (FR-007).

**Result**: No constitution violations.

## Phases

| Phase | Scope | Exit check |
|-------|-------|------------|
| 1. Data and sale rules | Migration adds the `cars` columns and `car_price_events`. `Car` gets the sale rules (price required when sold, positive whole cents, snapshots, first listed price, clearing on status change) and the history writes. | Model tests pass for FR-001, FR-002, FR-006, FR-007, FR-011, and the first listed price. |
| 2. Recording a sale | The staff car form gets sale price and dealer cost fields. Marking a car sold with a price saves it. Corrections and dealer cost changes write history. | Controller tests for sold without price, corrections, and cost history. |
| 3. Showing the difference | Staff car detail shows listed, sale, and difference with the below, above, or equal label. A car with no listed snapshot shows "not available". | Model tests for the difference, percentage, and label. Controller test for the staff detail page. |
| 4. Sales report | `Manage::SalesController#index` with a date range, rows, totals, and an empty message. | Controller tests for range filtering, totals, and the empty message. |
| 5. Privacy and verification | Customer pages checked against FR-009. System test for the sale flow. `bin/ci`. | Privacy tests pass. System test passes. `bin/ci` passes. |

## Project Structure

### Documentation (this feature)

```text
specs/004-sale-price-vs-listed/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Fields, rules, history
├── quickstart.md        # Validation guide
└── checklists/requirements.md
```

No `contracts/` directory. The feature adds one staff report page and fields on existing staff forms. The app has no external API. The route table below is the interface.

### Source Code (repository root)

```text
app/models/
├── car.rb                      # CHANGED: sale rules, snapshots, first listed price, clearing, history writes
└── car_price_event.rb          # NEW: one history entry (sale, correction, clearing, dealer cost)

app/controllers/
├── manage/cars_controller.rb   # CHANGED: permit sale_price and dealer_cost on update
└── manage/sales_controller.rb  # NEW: sales report by date range

app/views/
├── manage/cars/_form.html.erb  # CHANGED: sale price (when marking sold) and dealer cost fields (staff section)
├── manage/cars/show.html.erb   # CHANGED: listed, sale, difference, dealer cost, history
└── manage/sales/index.html.erb # NEW: report with range, rows, totals

db/migrate/                     # NEW: add sale columns to cars, create car_price_events, backfill first_listed_price

test/
├── models/car_test.rb                       # CHANGED: sale rules, difference, first listed, clearing
├── models/car_price_event_test.rb           # NEW
├── controllers/manage/cars_controller_test.rb  # CHANGED: sale and cost form behavior
├── controllers/manage/sales_controller_test.rb # NEW: report
├── controllers/sale_privacy_test.rb         # NEW: customer pages never show sale data or cost
└── system/sale_price_test.rb                # NEW: mark sold with a price in the browser
```

**Structure Decision**: Single Rails app. Sale rules stay in `Car`, matching how the car already holds its price and status rules. The report is a plain controller with a scope, since it needs no service object.

## Route Surface

| Method | Path | Audience | Purpose |
|--------|------|----------|---------|
| PATCH | `/manage/cars/:id` | Staff | Existing update. Now also accepts `sale_price` and `dealer_cost` (dollars) |
| GET | `/manage/sales?from=YYYY-MM-DD&to=YYYY-MM-DD` | Staff | Sales report for the date range |

Customer routes are unchanged.

## Cross-cutting notes

1. **FR-011 is enforced by the same rule as FR-001.** A sold car must have a sale price on every save. A pre-feature sold car therefore cannot be saved for any other change until it is priced, which is the rule the user chose.
2. **Clearing on status change.** Changing a sold car's status clears its sale price, its sale date, and its snapshot, and writes a `sale_price_cleared` event (FR-007).
3. **Customer views** do not render any new column. A privacy test checks the public car pages and favorites.
4. **Pre-sell interaction.** A pre-sold car in transit is not `sold` until it is marked sold, so this feature does not change the transit rules.
