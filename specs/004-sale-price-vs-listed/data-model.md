# Data Model: Sale Price vs Listed Price

## Car (changed)

Existing table `cars`. New columns:

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `sale_price_cents` | integer | when `status` is `sold` | Greater than 0. Dollars and cents, at most two decimal places, stored as integer cents (FR-002). |
| `sold_at` | datetime | when `status` is `sold` | Set when the car is marked sold. The sale date is its date (FR-003). |
| `asking_price_at_sale_cents` | integer | when `status` is `sold` | Copy of `asking_price_cents` at the moment of sale. Never changes after that (FR-004). |
| `first_listed_price_cents` | integer | no | Set once, the first time the car gets an asking price. Never changes after that (FR-010). |
| `dealer_cost_cents` | integer | no | Greater than 0 when present. Staff only. Optional (FR-012). |

**Changed rules**:
- `sale_price_cents`, `sold_at`, and `asking_price_at_sale_cents` are present on every save of a sold car. This makes FR-001 and FR-011 one rule.
- When `status` changes from `sold` to any other status, `sale_price_cents`, `sold_at`, and `asking_price_at_sale_cents` are cleared, and a `sale_price_cleared` event is written (FR-007).

**Unchanged**: `status`, `asking_price_cents`, `mileage`, `vin`, `lock_version`, and the contact fields.

## CarPriceEvent (new)

Table `car_price_events`.

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `car_id` | reference | yes | |
| `user_id` | reference | yes | Staff member who made the change. |
| `kind` | string | yes | One of `sold`, `sale_price_corrected`, `sale_price_cleared`, `dealer_cost_set`, `dealer_cost_changed`. |
| `from_cents` | integer | no | Previous value, where relevant. |
| `to_cents` | integer | no | New value, where relevant. |
| `created_at` | datetime | yes | |

Rows are append-only and written in the same transaction as the change they describe.

## Derived values (not stored)

| Value | Definition | When nil |
|-------|-----------|----------|
| `sale_difference_cents` | `sale_price_cents - asking_price_at_sale_cents` | If either is nil |
| `sale_difference_percent` | `sale_difference_cents / asking_price_at_sale_cents * 100`, rounded to one decimal place | If either is nil |
| `sale_difference_label` | "below listed" if negative, "above listed" if positive, "equal to listed" if zero | If the difference is nil, the label is "not available" (US2-3) |

## State transitions for sale fields

| From status | To status | Sale fields |
|-------------|-----------|-------------|
| available or reserved | sold | Requires `sale_price_cents`. Sets `sold_at` and `asking_price_at_sale_cents`. Writes `sold`. |
| sold, no sale price yet (pre-feature car) | sold, with a sale price | Sets `asking_price_at_sale_cents` from the current asking price, and `sold_at` if it is empty. Writes `sale_price_corrected` if the price was already set. |
| sold | sold | Changing `sale_price_cents` writes `sale_price_corrected`. The snapshot stays. |
| sold | available, reserved, in_transit | Clears the sale fields. Writes `sale_price_cleared` with the old price. |
| (any) | (any) | Setting or changing `dealer_cost_cents` writes `dealer_cost_set` or `dealer_cost_changed`. |

## Validation rules from the spec

| Rule | Source | Where enforced |
|------|--------|----------------|
| Sale price required when sold | FR-001, FR-011 | `Car` |
| Sale price > 0, at most two decimal places | FR-002 | `Car` |
| Sale date and staff recorded | FR-003 | `Car` (`sold_at`) and `CarPriceEvent` (`user_id`) |
| Dealer cost > 0 when present | FR-012 | `Car` |
| Customer pages never show sale data | FR-009 | Views and `sale_privacy_test` |
