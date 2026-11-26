# Data Model: Track Cars in Transit

## Car (changed)

Existing table `cars`. Changes:

| Field | Change | Rule |
|-------|--------|------|
| `status` | New value `in_transit` (3) | Existing values: `available` (0), `reserved` (1), `sold` (2). An in-transit car is not visible to customers unless it has a live pre-sell transit. |
| `mileage` | Required only when status is not `in_transit` (D1, proposed) | Integer, 0 or more. |
| `asking_price_cents` | Required only when status is not `in_transit` (D1, proposed) | Integer, greater than 0. |

Unchanged: `vin` (17 characters, unique among cars that are not sold), `make`, `model`, `year`, `dealership_id`, and all contact fields.

## Transit (new)

Table `transits`.

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `car_id` | reference | yes | The car in transit. |
| `dealership_id` | reference | yes | Destination dealership. Matches the car's `dealership_id` while open. |
| `origin` | string | yes | Where the car is coming from. Free text, up to 120 characters. Never shown to customers. |
| `expected_arrival_on` | date | yes | Changed only while the transit is open. |
| `state` | integer enum | yes | `open` (0), `arrived` (1), `cancelled` (2). Default `open`. `arrived` and `cancelled` are final. |
| `pre_sell` | boolean | yes | Default `false`. |
| `pre_sell_price_cents` | integer | when `pre_sell` is true | Greater than 0. Copied to the car's asking price on arrival. |
| `lock_version` | integer | yes | Optimistic locking, default 0. |
| `created_at`, `updated_at` | datetime | yes | |

**Constraints**:
- Partial unique index on `car_id` where `state = 0` (FR-002, SC-005).
- `pre_sell` true requires `pre_sell_price_cents` present (FR-011).

**State transitions**:

| From | To | Triggered by |
|------|----|--------------|
| open | arrived | Staff mark arrived. Car becomes `available` at its pre-sell price (or the price already set), and its pre-sell listing ends. If the car is already `sold`, its status stays `sold`; the arrival is still recorded. |
| open | cancelled | Staff cancel. Car is unchanged, except that a pre-sell listing ends. |
| arrived | (none) | Final. |
| cancelled | (none) | Final. |

**Derived**:
- `overdue?`: open and `expected_arrival_on < Date.current`.
- `public_pre_sell?`: open, `pre_sell` true, and `pre_sell_price_cents` present.

## TransitEvent (new)

Table `transit_events`.

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `transit_id` | reference | yes | |
| `user_id` | reference | yes | Staff member who made the change. |
| `kind` | string | yes | One of `recorded`, `expected_arrival_changed`, `pre_sell_set`, `pre_sell_price_changed`, `arrived`, `cancelled`. |
| `from_value` | string | no | Previous value, where relevant. |
| `to_value` | string | no | New value, where relevant. |
| `created_at` | datetime | yes | |

Rows are append-only. They are written in the same transaction as the change they describe.

## Relationships

- `Car` has many `Transit`. At most one is open at a time.
- `Transit` belongs to `Car`, belongs to `Dealership` (destination), and has many `TransitEvent`.
- `TransitEvent` belongs to `Transit` and `User`.

## Validation rules from the spec

| Rule | Source | Where enforced |
|------|--------|----------------|
| VIN is 17 characters and unique among non-sold cars | FR-001 (via existing car rule) | `Car` (existing) |
| Origin and expected arrival are required | US1 scenario 3 | `Transit` |
| One open transit per car | FR-002, SC-005 | Database index and `Transit` validation |
| Pre-sell requires a price | FR-011, Edge case | `Transit` |
| Customer pages never show origin | FR-009 | Views and controller tests |
