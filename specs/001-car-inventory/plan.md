# Implementation Plan: Car Inventory

**Branch**: `001-car-inventory` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-car-inventory/spec.md`

## Summary

Build a dealership inventory web app in the Rails 8.1 app already in this repository. Staff sign in to manage car listings with photos, rich-text descriptions, and feature tags, and see each other's changes live. Customers search and filter available cars without an account and save favorites in their browser. The plan uses Rails' built-in features for each requirement, with no third-party gems except `bcrypt` and `image_processing`, which Rails 8 already includes or expects.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.4.1

**Primary Dependencies**: Rails built-ins: Active Record, Action Controller, Action View, Action Text, Active Storage, Action Mailer, Active Job, Turbo, Stimulus, Propshaft, importmap. Gems: `bcrypt` (uncomment in Gemfile, for `has_secure_password`), `image_processing` (already in Gemfile, for photo variants). Solid Queue, Solid Cache, and Solid Cable are already in the app.

**Storage**: SQLite (Rails 8 default), with Active Storage on local disk. Browser `localStorage` for customer favorites.

**Testing**: Minitest with fixtures, controller/integration tests, and system tests (Capybara with a headless browser) for the live-update flows. `bin/ci` runs the full suite.

**Target Platform**: Web. Desktop and mobile browsers. Deployed with Kamal, Thruster, and Puma (Dockerfile already generated).

**Project Type**: Web application (server-rendered Rails with Hotwire).

**Performance Goals**: Filter results in under 2 seconds (SC-004). Live updates visible within 5 seconds (SC-002, SC-003).

**Constraints**: No customer accounts or customer email (spec clarification). Staff contact details never shown to customers or in share links (FR-020, FR-019). Share links expire after 7 days (FR-018).

**Scale/Scope**: Under 10 dealership locations, a few thousand cars, a handful of staff per location. Small enough for one SQLite database and one Puma process with jobs running in-process (`SOLID_QUEUE_IN_PUMA`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Spec Before Code | `spec.md` exists and passes the checklist, with its clarification resolved. | PASS |
| II. Test-Backed Changes | Every requirement has an acceptance scenario that can become a test. Quickstart lists the checks. | PASS |
| III. Simplicity First | Built-in Rails features are chosen over gems. Favorites use `localStorage`, not a database. Share links use `generates_token_for`, not a table. Only two gems are added, and both are already expected. | PASS |
| IV. Small, Reviewable Changes | Work splits into the phases below, each usable on its own. | PASS |
| V. Decisions Are Recorded | Each choice with alternatives is in `research.md`. | PASS |

No gate violations, so the Complexity Tracking table is empty.

## Rails Features by Requirement

| Requirement | Rails feature | Notes |
|-------------|---------------|-------|
| FR-001, FR-002 (staff sign-in, throttling) | `bin/rails generate authentication`, `has_secure_password`, `rate_limit` | Throttle keyed by the submitted email, per FR-002. Error message does not reveal whether the email exists. |
| FR-003 to FR-006 (listings, VIN) | Active Record: `enum`, `normalizes`, validations, partial unique index | VIN is normalized to uppercase, then checked for 17 characters and uniqueness among non-sold cars. |
| FR-007 (photos) | Active Storage: `has_many_attached :photos`, variants via `image_processing` | Attachments are saved in a transaction with the car, so a failed upload keeps the previous photos (edge case). |
| FR-008 (rich text) | Action Text: `has_rich_text :description` | Trix editor in the staff form. |
| FR-009, FR-012 (feature tags, filters) | `has_many :through` join, scopes, `params.expect` | Filters combine as chained scopes. |
| FR-010, SC-002 (live updates) | Turbo Streams: `broadcasts_to`, `turbo_stream_from`; Solid Cable | Staff views subscribe to the car and the inventory list. |
| FR-021 (conflicting edits) | Optimistic locking: `lock_version` column | A stale save raises `StaleObjectError`; the controller asks the staff member to reload. |
| FR-011, FR-013 (public search) | Scopes for `available`, public controller without auth | Reserved and sold cars are excluded by the `available` scope. |
| FR-014, FR-015 (favorites) | Stimulus controller with `localStorage` | Stores car IDs with the last-seen price-drop time. |
| FR-016 (price drop badge) | `price_dropped_at` timestamp on `Car`, set in the model when the price falls | Customer badge is computed client-side against the local last-seen time. |
| FR-017 (nightly report) | Active Job, Solid Queue `config/recurring.yml`, Action Mailer | `deliver_later`. Job selects cars with `updated_at` older than 60 days. |
| FR-018, FR-019 (share link) | `generates_token_for :share, expires_in: 7.days` | No table. Share view omits contact fields. |
| FR-020 (private contact details) | Separate partials; contact fields rendered only in staff views | Covered by request tests that check customer and share responses. |
| Performance (SC-004) | Fragment caching (`cache car`) backed by Solid Cache | Cache keys include `updated_at`, so changes invalidate automatically. |

## Interface Surface

The spec asks for no public API, so this plan doesn't add a separate `contracts/` folder. The routes below are the complete external surface:

| Method | Path | Audience | Purpose |
|--------|------|----------|---------|
| GET | `/session/new` | Staff | Sign-in form |
| POST | `/session` | Staff | Sign in (rate limited) |
| DELETE | `/session` | Staff | Sign out |
| GET | `/cars` | Customers and staff | Browse and filter (staff see all statuses) |
| GET | `/cars/:id` | Customers and staff | Car detail |
| GET | `/favorites` | Customers | Favorites list, read from `?ids=` (rendered by server, data from `localStorage`) |
| GET, POST, PATCH, DELETE | `/manage/cars` and `/manage/cars/:id` | Staff only | Create, edit, remove listings |
| POST | `/manage/cars/:id/share` | Staff only | Create share link |
| GET | `/share/:token` | Anyone with the link | Read-only car page for 7 days |
| GET | `/up` | Monitoring | Health check (built in) |

## Project Structure

### Documentation (this feature)

```text
specs/001-car-inventory/
├── spec.md
├── plan.md                  # This file
├── research.md              # Phase 0 decisions
├── data-model.md            # Phase 1 entities and fields
├── quickstart.md            # Validation guide
├── checklists/
│   └── requirements.md
└── tasks.md                 # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── application_controller.rb
│   ├── session_controller.rb        # generated: sign in/out, rate_limit
│   ├── cars_controller.rb           # public browse, filters, detail
│   ├── favorites_controller.rb      # reads favorites by id
│   ├── shares_controller.rb         # public share page
│   └── manage/
│       ├── cars_controller.rb       # staff CRUD, status/price changes
│       └── shares_controller.rb     # create share link
├── models/
│   ├── user.rb                      # generated: staff login
│   ├── session.rb                   # generated
│   ├── car.rb                       # enum, normalizes, scopes, broadcasts, token
│   ├── feature.rb
│   └── car_feature.rb
├── mailers/
│   └── staff_mailer.rb              # nightly stale-listing report
├── jobs/
│   └── stale_listing_report_job.rb
├── javascript/controllers/
│   └── favorites_controller.js      # localStorage favorites and badge
└── views/
    ├── cars/
    ├── manage/cars/
    ├── favorites/
    ├── shares/
    └── staff_mailer/

config/
├── recurring.yml                    # nightly job schedule
└── routes.rb

test/
├── models/
├── controllers/
├── mailers/
├── jobs/
└── system/                          # live-update and favorites flows
```

**Structure Decision**: One Rails app at the repository root, using the default Rails layout. No separate frontend or API app, because the spec requires neither.

## Phases

1. **Foundation**: Enable `bcrypt`, run the authentication generator, add the `Car`, `Feature`, `CarFeature`, and `Dealership` models with migrations, and set up Action Text and Active Storage.
2. **Staff management**: Staff CRUD for cars, VIN rules, status and price fields, photos, descriptions, and tags.
3. **Live updates**: Add Turbo Stream broadcasts and optimistic locking. Test conflicting saves.
4. **Customer browsing**: Public search and filters, fragment caching, and the car detail page.
5. **Favorites and price drops**: Stimulus favorites with `localStorage`, plus the price-drop timestamp and badge.
6. **Share links**: Token generation, the 7-day expiry, and the public page without contact details.
7. **Nightly report**: Stale-listing query, mailer, and the recurring job.
8. **Hardening**: Request tests for private fields, rate limiting, and system tests for live updates.

## Re-check: Constitution (post-design)

After the data model and research were written, the design still follows every principle above. No new gems or infrastructure were added beyond the plan. PASS.
