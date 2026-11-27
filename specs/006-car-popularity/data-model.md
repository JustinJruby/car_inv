# Data Model: Car Popularity by Favorites

## Favorite (new)

Table `favorites`.

| Field | Type | Required | Rule |
|-------|------|----------|------|
| `car_id` | reference | yes | The saved car. |
| `visitor_id` | string (36) | yes | Random UUID from the visitor's cookie. The only identifier stored (FR-002). |
| `saved_at` | datetime | yes | When the visitor saved the car. Used for the 30-day window (FR-006). |
| `removed_at` | datetime | no | When the visitor removed the car. Empty while the favorite is active. |
| `created_at`, `updated_at` | datetime | yes | |

**Constraints**:
- At most one active favorite per visitor per car: a partial unique index on `(car_id, visitor_id)` where `removed_at` is empty (FR-002 and the edge case on repeated saves).
- `visitor_id` must be a UUID (format check in the model).
- `removed_at`, when present, is not before `saved_at`.

**State transitions**:

| From | To | Triggered by |
|------|----|--------------|
| (none) | active (`removed_at` empty) | Visitor saves the car |
| active | removed (`removed_at` set) | Visitor removes the car |
| removed | active (new row) | Visitor saves the car again |

## Car (unchanged)

Gains no column. A car's favorite count is a query over active `Favorite` rows, not a stored value.

## Derived values

| Value | Definition |
|-------|-----------|
| Favorite count (all time) | Number of `Favorite` rows for the car with `removed_at` empty |
| Favorite count (last 30 days) | Number of `Favorite` rows for the car with `removed_at` empty and `saved_at` within the last 30 days |
| Ranking order | Favorite count, highest first; ties by make, then model |

## Validation rules from the spec

| Rule | Source | Where enforced |
|------|--------|----------------|
| No personal detail is stored | FR-002, SC-003 | Table has no such columns; privacy test |
| One active favorite per visitor per car | Edge case, FR-002 | Partial unique index and model validation |
| Removed favorites leave the page and the counts | FR-008 | Scopes on active rows |
| Counts never below zero | Edge case | Counts are queries over active rows |
