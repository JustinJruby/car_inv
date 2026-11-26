# Data Model: Modern UI with Tailwind CSS

**No data model changes.** This feature restyles views only (FR-006: no new routes, fields, validations, or JavaScript features).

The entities and schema are unchanged from the 001 feature. See [../001-car-inventory/data-model.md](../001-car-inventory/data-model.md) for `Car`, `Dealership`, `Feature`, `CarFeature`, `User`, and `Session`, and `db/schema.rb` for the authoritative schema.

## Display-state mapping (view-only)

These are presentation rules, not stored data. They are defined in views and in the `.badge` component class.

| Value | Source | Display |
|-------|--------|---------|
| `Car#status` = `available` | enum (0) | Emerald badge, label "Available" |
| `Car#status` = `reserved` | enum (1) | Amber badge, label "Reserved" |
| `Car#status` = `sold` | enum (2) | Slate badge, label "Sold" |
| Flash `notice` | controller `notice:` | Emerald alert with check icon |
| Flash `alert` | controller `alert:` or `flash.now[:alert]` | Red alert with "!" icon |

Badge labels must match the existing text. Any change to label wording needs a spec-driven note in the plan (SC-001 exception).
