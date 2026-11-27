# Tasks: Car Popularity by Favorites

**Input**: Design documents from `/specs/006-car-popularity/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Gate**: The privacy change (spec Clarifications, Q1 = B, which moves favorites to the server with a random visitor identifier) must be confirmed before implementation starts. Tasks T002 to T013 depend on it.

**Tests**: Included. Constitution Principle II requires tests for each behavior change, and the spec's acceptance scenarios name each one.

**Organization**: The spec has one user story (US1, the staff ranking). Moving favorites to the server is foundational work, because the counts depend on it, so it comes first.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 (see the most-favorited cars, P1)

---

## Phase 1: Setup

- [x] T001 Run `bin/rails test` and `bin/rails test:system` before any change, and record the counts in `specs/006-car-popularity/research.md` under a new "Baseline" note

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Favorites are stored on the server, tied to a random visitor identifier. The ranking and the counts depend on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Create migration `db/migrate/<timestamp>_create_favorites.rb` for `favorites`. Constrained fields per `data-model.md`: `Favorite.car_id` (reference, required), `Favorite.visitor_id` (string, 36 characters, required), `Favorite.saved_at` (datetime, required), `Favorite.removed_at` (datetime, nullable). Add `created_at` and `updated_at`. Add a partial unique index on `(car_id, visitor_id)` where `removed_at IS NULL`, named `index_favorites_on_car_and_visitor_active`, so one visitor has at most one active favorite per car.
- [x] T003 Run `bin/rails db:migrate` and confirm `db/schema.rb` lists the table, the nullable `removed_at`, and the partial index.
- [x] T004 [P] Write model tests in `test/models/favorite_test.rb` for: `Favorite.visitor_id` must be a UUID; `Favorite.saved_at` is required; `Favorite.removed_at`, when present, is not before `Favorite.saved_at`; one active favorite per visitor per car (both the model validation and the database index); saving again after a removal creates a new row; the active scope leaves out removed favorites; the 30-day scope keeps only active favorites saved in the last 30 days.
- [x] T005 [P] Create `app/models/favorite.rb`: `belongs_to :car`; validation that `Favorite.visitor_id` is a UUID; presence of `Favorite.saved_at`; validation that `Favorite.removed_at` is not before `Favorite.saved_at`; a uniqueness validation over active rows; scopes `active` (where `Favorite.removed_at` is nil) and `saved_within(window)` (where `Favorite.saved_at` is in the window).
- [x] T006 Write controller tests in `test/controllers/favorites_controller_test.rb` (update the existing file) for: POST `/cars/:car_id/favorite` creates one active favorite for the visitor's cookie; a second POST creates no duplicate; DELETE sets `Favorite.removed_at`; GET `/favorites` lists only this visitor's active favorites from the server; the visitor cookie is httponly and signed.
- [x] T007 Create `app/controllers/concerns/visitor.rb`: a `visitor_id` method that reads the signed, permanent, httponly cookie `visitor_id`, and creates a random UUID (`SecureRandom.uuid`) when the cookie is missing. This is the only identifier stored with a favorite (research R2).
- [x] T008 Update `app/controllers/favorites_controller.rb` to include the visitor concern and add `create` (save for this visitor, stored as an active `Favorite`) and `destroy` (set `Favorite.removed_at` on this visitor's active favorite). Change `index` to read this visitor's active favorites from the server instead of the `ids` parameter. Do not migrate browser favorites (research R7).
- [x] T009 Update `config/routes.rb`: nest `resource :favorite, only: %i[create destroy]` under `resources :cars`, so `POST` and `DELETE /cars/:car_id/favorite` exist. Keep the existing `cars` and `favorites` routes.
- [x] T010 Update `test/system/favorites_test.rb` (existing file) so a visitor saves a car, reloads the page, and still sees it on `/favorites` from the server; removing it takes it off the page. The browser storage is no longer the source of favorites.
- [x] T011 Update `app/javascript/controllers/favorites_controller.js` so the save and remove buttons call the server (`POST` and `DELETE` to `/cars/:id/favorite`, with the page's CSRF token), and set the button label from the server's answer instead of from browser storage.
- [x] T012 Update `app/javascript/controllers/favorites_store.js` to keep only the last-seen time for each saved car, for the "Price dropped" badge (spec 001, US6). Remove the functions that store favorite membership.
- [x] T013 Update `app/javascript/controllers/favorites_list_controller.js` and `app/views/favorites/index.html.erb`: the page no longer redirects from browser storage. It renders the server's favorites, and keeps the `data-price-dropped-at` values and the "Price dropped" badge targets.

**Checkpoint**: Favorites are saved on the server. The favorites page and the save and remove buttons work from the server.

---

## Phase 3: User Story 1 - See the most-favorited cars (Priority: P1) 🎯 MVP

**Goal**: A staff member sees cars ranked by active favorites, with a choice of all time or the last 30 days, and ties ordered by make and model (FR-003 to FR-006).

**Independent Test**: Save favorites on three cars from two visitors, remove one, and confirm the ranking order, the counts, the 30-day window, and the empty message.

### Tests for User Story 1

- [x] T014 [US1] Create `test/controllers/manage/popularity_controller_test.rb` with tests for: a signed-out request redirects to sign-in; cars are ordered most favorited first with each count (US1 scenario 1); a removed favorite does not count (US1 scenario 2); "No favorites yet" when there are none (US1 scenario 3); cars that are sold or in transit still appear (US1 scenario 4); ties are ordered by make, then model (FR-005); `window=30` counts only active favorites saved in the last 30 days, and the default is all time (FR-006, US1 scenario 5).

### Implementation for User Story 1

- [x] T015 [US1] Add a route in `config/routes.rb` inside the `manage` namespace: `get "popularity", to: "popularity#index"`, so `manage_popularity_path` exists (staff only).
- [x] T016 [US1] Add `Favorite.ranking(window:)` to `app/models/favorite.rb`. It groups active favorites by `car_id`, optionally limits them with `saved_within` for the 30-day window, and returns cars with their counts ordered by count (highest first), then `Car` make, then model (FR-005, research R4).
- [x] T017 [US1] Create `app/controllers/manage/popularity_controller.rb` with `index`. The `window` parameter is `all` (the default) or `30`. It uses `Favorite.ranking` and loads the cars, so their status can be shown.
- [x] T018 [US1] [P] Create `app/views/manage/popularity/index.html.erb`: the window choice (all time, last 30 days), a table with the car, its status badge, and its favorite count, and the empty message "No favorites yet".

**Checkpoint**: The ranking works for staff with the window choice.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T019 Create `test/controllers/favorite_privacy_test.rb` for: the stored favorite has only `car_id`, `visitor_id`, the two times, and the timestamps, with no name or email (FR-002, SC-003); the visitor cookie is httponly and signed (research R2); the public inventory, car pages, and favorites page show no favorite count or ranking (FR-004, SC-004).
- [x] T020 Run `bin/rails test` and `bin/rails test:system` and compare the counts with the baseline from T001. Record the final counts in `specs/006-car-popularity/research.md`.
- [ ] T021 Walk through `specs/006-car-popularity/quickstart.md` section 5 on the development server and record any difference from the expected results. This needs a browser, so it stays open until it is done.
- [x] T022 Run `bin/ci` and confirm every step passes.
- [x] T023 Compare `db/schema.rb` with `data-model.md`: `removed_at` is nullable, `visitor_id` is 36 characters, and the partial unique index is on `(car_id, visitor_id)` where `removed_at` is nil.

---

## Dependencies & Execution Order

- **Phase 1** has no dependencies.
- **Phase 2** depends on Phase 1 and on the privacy confirmation. T002 and T003 come first, then T004 and T005 (in parallel), then T006 and T007, then T008 and T009, then T010 to T013.
- **US1** depends on Phase 2, because the ranking reads server favorites. T014 comes before T015 to T018.
- **Final Phase** depends on all of the above. T019 is written last here, but it guards behavior from Phases 2 and 3.

## Parallel Opportunities

- T004 and T005 (model tests and model) can run in parallel after T002 and T003.
- T018 (view) can run alongside T016 and T017.
- T011 to T013 (browser code) touch different files, so they can be done in parallel.

## Implementation Strategy

### MVP (User Story 1, after Phase 2)

1. Complete Phase 1 and Phase 2 (server favorites).
2. Complete US1 (the ranking).
3. Stop and check: save favorites from two visitors, then open the ranking.

## Notes

- Tests for each behavior come before the code that implements it (Principle II). T019 is the privacy guard and is written in the final phase, so it is the last check on FR-002 and FR-004.
- Do not migrate favorites saved in browsers before this change (research R7). The favorites page reads only server favorites after T008.
- The price-drop badge keeps working from the browser's last-seen time (T012, T013).
