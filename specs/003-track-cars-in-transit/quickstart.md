# Quickstart: Track Cars in Transit

Validation guide for the feature. Run after each phase in plan.md. Blocked until D1 and D2 are decided (see research.md R2, R9).

## Prerequisites

- Seeded development database (`bin/rails db:prepare db:seed`). Staff login: `staff@example.test`.
- Migrations for this feature applied (`bin/rails db:migrate`).

## 1. Model and database rules

```bash
bin/rails test test/models/transit_test.rb test/models/transit_event_test.rb test/models/car_test.rb
```

Expected: all pass. The tests cover one open transit per car (including the database index), state changes, pre-sell price rules, history rows, and the D1 car validations.

## 2. Staff transit pages

```bash
bin/rails test test/controllers/manage/transits_controller_test.rb
```

Expected: staff can record, list, arrive, cancel, reschedule, and set pre-sell. Signed-out requests redirect to sign-in.

## 3. Customer privacy and pre-sell visibility

```bash
bin/rails test test/controllers/transit_privacy_test.rb
bin/rails test:system test/system/pre_sell_test.rb
```

Expected:
- Customer pages never contain the origin, expected arrival history, or staff contact details (FR-009).
- A pre-sell car with a price appears in `/cars` with its price and expected arrival date, labeled as a pre-sell.
- A transit without a price, or not marked for pre-sell, does not appear in `/cars`.

## 4. Manual walk-through (development server)

1. Sign in as staff and open `/manage/transits`. Expected: empty state, "No cars are in transit."
2. Record a car: VIN `1HGCM82633A123456`, make, model, year, origin "Auction, Phoenix", expected arrival tomorrow. Expected: it appears in the list.
3. Record a second car with expected arrival last week. Expected: it is flagged overdue and listed first.
4. Mark the first car for pre-sell with a price. Sign out and open `/cars`. Expected: the car appears with the price, a "Pre-sell" label, and its expected arrival date. No origin.
5. Mark the car arrived. Expected: it leaves the transit list, and it appears as an available car at the pre-sell price.
6. Cancel the second transit. Expected: it leaves the list, and the car is unchanged.
7. Open a transit's detail page. Expected: each change is listed with your name and the time.

## 5. Full check

```bash
bin/ci
```

Expected: every step passes, including the stale-listing report tests, which must confirm that in-transit cars are excluded.
