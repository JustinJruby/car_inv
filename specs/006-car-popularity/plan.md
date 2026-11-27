# Implementation Plan: Car Popularity by Favorites

**Branch**: `feature/006-car-popularity` | **Date**: 2026-11-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-car-popularity/spec.md`

## Summary

Favorites move from the browser to the server (spec Clarifications, Q1 = B). Each save and removal becomes a row tied to a random visitor identifier held in a cookie, so the server can count them. Staff see a ranking of cars by active favorites, with a choice of all-time or last 30 days, and ties ordered by make and model. Customers see no counts (Q2 = A). The browser keeps only what it needs for the "Price dropped" badge, which is the last time each saved car was seen.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.4.1

**Primary Dependencies**: Existing stack only: Active Record, Action Controller and View, Turbo, Stimulus, importmap. No new gems.

**Storage**: SQLite. One new table, `favorites`. Browser storage keeps only the last-seen time for the price-drop badge (spec 001, US6).

**Testing**: Minitest. Model tests for counting and windows, controller tests for save, remove, and the staff ranking, a privacy test for the cookie and stored data, and one system test for save and ranking.

**Target Platform**: Web, desktop and phone-width browsers.

**Project Type**: Web application (server-rendered Rails with Hotwire).

**Performance Goals**: The ranking loads in under 2 seconds at the current scale (a few thousand cars). Counts update on the next page load (FR-007).

**Constraints**:
- FR-002: no name, email, or other personal detail stored. The random identifier is the only identifier.
- FR-004: no customer page shows a count or a ranking.
- FR-008: removing a favorite removes it from the favorites page and from the counts.

**Scale/Scope**: A few thousand cars, a few thousand visitors' favorites at most, under 10 dealership locations.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Spec Before Code | `spec.md` is in `specs/006-car-popularity/`, with clarifications recorded. | PASS |
| II. Test-Backed Changes | Each FR and acceptance scenario has a planned test (see quickstart). | PASS |
| III. Simplicity First | No new gems. Favorites are rows in one table; the count is a query, not a stored counter. The visitor identifier is a random value in a cookie, with no account system. | PASS |
| IV. Small, Reviewable Changes | Four phases, each leaving the app working and tested. | PASS |
| V. Decisions Are Recorded | Each choice with alternatives is in `research.md`. | PASS |

**Gate to confirm before tasks**: the spec changes spec 001, US5 (favorites move from the browser to the server) and FR-002 now allows a random identifier. The spec's checklist asks for confirmation of this privacy change. Tasks are not generated until it is confirmed.

**Result**: No constitution violations. One confirmation pending (above).

## Phases

| Phase | Scope | Exit check |
|-------|-------|------------|
| 1. Data and rules | Migration for `favorites`. `Favorite` model: validations, active and windowed scopes. Visitor identifier cookie. | Model tests pass for one active favorite per visitor per car, windows, and the count. |
| 2. Server favorites | Save and remove endpoints for a car. The favorites page reads the server for the visitor's identifier. The browser's save and remove buttons call the server. Price-drop badge keeps working from the browser's last-seen time. | Controller tests for save, remove, and the favorites page. Existing favorites system tests updated. |
| 3. Staff ranking | `Manage::PopularityController#index` with the window choice (all time or last 30 days) and ties ordered by make and model. | Controller tests for order, ties, windows, and the empty message. |
| 4. Privacy and verification | Privacy tests: stored data holds no personal detail, the cookie is httponly, customer pages show no counts. System test for save and ranking. `bin/ci`. | Privacy tests pass. `bin/ci` passes. |

## Project Structure

### Documentation (this feature)

```text
specs/006-car-popularity/
├── spec.md
├── plan.md              # This file
├── research.md          # Design decisions
├── data-model.md        # Favorite entity, rules, counts
├── quickstart.md        # Validation guide
└── checklists/requirements.md
```

No `contracts/` directory. The browser calls two internal endpoints, and they are listed in the route surface below.

### Source Code (repository root)

```text
db/migrate/                              # NEW: create favorites
app/models/favorite.rb                   # NEW: validations, active and windowed scopes, counts
app/controllers/concerns/visitor.rb      # NEW: random visitor identifier in a cookie
app/controllers/favorites_controller.rb  # CHANGED: save, remove, and list from the server
app/controllers/cars_controller.rb       # UNCHANGED: customers see no counts (FR-004)
app/controllers/manage/popularity_controller.rb  # NEW: staff ranking
app/views/manage/popularity/index.html.erb       # NEW: ranking with window choice
app/views/favorites/index.html.erb       # CHANGED: reads server favorites; price-drop badge kept
app/javascript/controllers/favorites_controller.js    # CHANGED: save and remove call the server
app/javascript/controllers/favorites_store.js         # CHANGED: keeps last-seen time only
app/javascript/controllers/favorites_list_controller.js  # CHANGED: no longer redirects from browser storage
config/routes.rb                         # CHANGED: favorite routes; manage popularity route
test/models/favorite_test.rb             # NEW
test/controllers/favorites_controller_test.rb  # CHANGED: server save, remove, list
test/controllers/manage/popularity_controller_test.rb  # NEW
test/controllers/favorite_privacy_test.rb      # NEW: stored data and cookie
test/system/favorites_test.rb            # CHANGED: save on server, reload keeps it
```

**Structure Decision**: Single Rails app. Favorites get their own model, since they have rows with times. The visitor identifier lives in a concern, so both the favorites and the ranking can use it.

## Route Surface

| Method | Path | Audience | Purpose |
|--------|------|----------|---------|
| POST | `/cars/:car_id/favorite` | Visitors (no sign-in) | Save a car as a favorite for this visitor |
| DELETE | `/cars/:car_id/favorite` | Visitors (no sign-in) | Remove the favorite for this visitor |
| GET | `/favorites` | Visitors (no sign-in) | This visitor's active favorites, from the server |
| GET | `/manage/popularity?window=all\|30` | Staff | Ranking by active favorites |

## Cross-cutting notes

1. **Visitor identifier.** Created on the first save or visit, as a random UUID in a permanent, httponly cookie. It is not tied to an account and is never shown.
2. **Counts.** A car's count is its active favorites (`removed_at` empty). The ranking with the 30-day window counts favorites with `saved_at` in the last 30 days that are still active.
3. **Price-drop badge.** Still computed in the browser from the car's price-dropped time and the browser's last-seen time for that car (spec 001, US6). Only the last-seen time is kept in the browser now.
4. **Existing browser favorites.** Favorites saved before this change stay in the browser and are not migrated. Recorded as a decision in `research.md` (R7).
5. **Customer pages.** The public car and inventory pages are unchanged. No count or ranking is rendered there (FR-004, SC-004).
