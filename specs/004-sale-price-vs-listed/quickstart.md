# Quickstart: Sale Price vs Listed Price

Validation guide. Run after each phase in plan.md.

## Prerequisites

- Seeded development database (`bin/rails db:prepare db:seed`). Staff login: `staff@example.test`.
- Migrations for this feature applied (`bin/rails db:migrate`).

## 1. Sale rules (model)

```bash
bin/rails test test/models/car_test.rb test/models/car_price_event_test.rb
```

Expected: all pass. The tests cover:
- A sold car needs a positive sale price (FR-001, FR-002).
- A pre-feature sold car with no sale price cannot be saved for other changes (FR-011).
- The asking price snapshot and first listed price (FR-004, FR-010).
- The difference, its percentage, and its label, including "not available" (US2).
- Clearing the sale when the status changes (FR-007).

## 2. Recording a sale (staff form)

```bash
bin/rails test test/controllers/manage/cars_controller_test.rb
```

Expected: a sale with a price is saved and writes a `sold` event. A correction writes `sale_price_corrected`. A dealer cost change writes `dealer_cost_changed`.

## 3. Sales report

```bash
bin/rails test test/controllers/manage/sales_controller_test.rb
```

Expected: only cars sold within the range appear, totals are correct, and an empty range shows "No sales in this period".

## 4. Customer privacy

```bash
bin/rails test test/controllers/sale_privacy_test.rb
bin/rails test:system test/system/sale_price_test.rb
```

Expected: no customer page shows a sale price, listed snapshot, dealer cost, or difference. The system test marks a car sold in the browser and checks the difference on the staff page.

## 5. Full check

```bash
bin/ci
```

Expected: every step passes.
