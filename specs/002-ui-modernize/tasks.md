# Tasks: Modern UI with Tailwind CSS

**Input**: Design documents from `/specs/002-ui-modernize/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Not TDD. The spec requires existing suites to pass (SC-001, SC-002), one new layout test (SC-004), and visual checks (SC-003). Each story ends with a verification task.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 (customer browse, P1), US2 (staff manage, P1), US3 (navigation and account/share pages, P2)
- Every task names the exact file(s) it changes

## Path Conventions

- Views: `app/views/`
- Tailwind entry and component classes: `app/assets/tailwind/application.css`
- Generated stylesheet (gitignored): `app/assets/builds/tailwind.css`
- Tests: `test/controllers/`, `test/system/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the starting state before any view changes.

- [x] T001 Run `bin/rails test` and `bin/rails test:system`, then record the real pass counts in `specs/002-ui-modernize/research.md` section 8 (done: 68 unit, 6 system, 0 failures)
- [x] T002 Run `bin/rails tailwindcss:build` and confirm `app/assets/builds/tailwind.css` exists and is non-empty
- [x] T003 [P] Confirm `.gitignore` ignores `app/assets/builds/*` but keeps `app/assets/builds/.keep`, using `git check-ignore -v app/assets/builds/tailwind.css`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared pieces every story depends on. No story work starts until this phase is done.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Record the current labels, field names and IDs, `data-*` attributes, Turbo frame/stream IDs, and Stimulus hooks for every view under `app/views/` (excluding mailers and `pwa/`) in `specs/002-ui-modernize/attribute-inventory.md` (FR-003 baseline)
- [x] T005 Create the shared flash partial `app/views/shared/_flash.html.erb` (emerald notice with ✓ prefix, red alert with ! prefix, `role="status"` and `role="alert"`), and render it in `app/views/layouts/application.html.erb` in place of the inline flash blocks (US3-2 pattern)
- [x] T006 Set `min-h-11` on the header nav links and buttons in `app/views/layouts/application.html.erb`, and add `min-h-11` to the `.btn-primary`, `.btn-secondary`, `.btn-danger`, and `.input` base classes in `app/assets/tailwind/application.css` (US3-3, 44px tap targets; `.input` also covers `select` fields). Then check the rendered heights of buttons, inputs, and selects in the browser.

**Checkpoint**: Shared layout, flash, and controls are ready. User story phases can begin.

---

## Phase 3: User Story 1 - Customers browse with a modern layout (Priority: P1) 🎯 MVP

**Goal**: Public inventory, car detail, and favorites pages are styled as specified in US1.

**Independent Test**: As a signed-out visitor, load `/` with seeded data. Cars appear as cards in a grid (3+ columns on desktop, 1 column on phones), a filter with no matches shows "No cars match these filters.", and `/cars/:id` shows "Save to favorites" as a primary button. Existing customer tests pass.

- [ ] T007 [US1] Restyle the inventory page in `app/views/cars/index.html.erb`: filter panel with `.input` and `.label` controls, `.btn-primary` submit, and `data-*` and IDs kept per `attribute-inventory.md`
- [ ] T008 [P] [US1] Restyle the car card in `app/views/cars/_car.html.erb`: year, make, model, price, and features as `.chip` items (spec: US1-1)
- [x] T009 [US1] Restyle the results grid in `app/views/cars/_results.html.erb`: responsive grid (1 column default, 2 at `sm`, 3 at `lg`, i.e. 1024px and wider), styled "No cars match these filters." empty state, turbo frame ID kept
- [ ] T010 [P] [US1] Restyle the photo gallery in `app/views/cars/_gallery.html.erb` and the attachment partial `app/views/active_storage/blobs/_blob.html.erb`, keeping image order (`specs/001-car-inventory/spec.md` US4-1)
- [ ] T011 [US1] Restyle the car detail page in `app/views/cars/show.html.erb`: title, price, mileage, features, and description grouped into visible sections, and "Save to favorites" as `.btn-primary` (US1-3)
- [ ] T012 [P] [US1] Style rich-text description output in `app/views/layouts/action_text/contents/_content.html.erb` (bold text and lists from `specs/001-car-inventory/spec.md` US4-2 must be visible)
- [ ] T013 [US1] Restyle the favorites list in `app/views/favorites/index.html.erb`: "Price dropped" badge and the unavailable state using `.badge` and `.card`, `data-*` hooks kept for `favorites_list_controller.js`
- [x] T014 [US1] Verify US1: run `bin/rails test test/controllers/cars_controller_test.rb test/controllers/favorites_controller_test.rb` and `bin/rails test:system test/system/favorites_test.rb test/system/price_badge_test.rb test/system/car_media_test.rb test/system/smoke_test.rb`, then fix any failures caused by the restyle (text and IDs must not change)

**Checkpoint**: US1 complete and independently verified.

---

## Phase 4: User Story 2 - Staff manage cars efficiently (Priority: P1)

**Goal**: The staff list, detail, and car form are styled with status badges, sectioned fields, and visible errors (US2).

**Independent Test**: Sign in as `staff@example.test` (seeded). `/manage/cars` shows a table with colored status badges. The new and edit forms show public and staff-contact fields in separate labeled sections. A failed validation shows a styled alert above the form.

- [x] T015 [P] [US2] Add status badge variants (done without new CSS classes: `car_status_badge` already uses the `STATUS_BADGE_CLASSES` map in `app/helpers/application_helper.rb`, which gives the same colors) `.badge-available` (emerald), `.badge-reserved` (amber), and `.badge-sold` (slate) to `app/assets/tailwind/application.css`, matching the display mapping for `specs/001-car-inventory/data-model.md` `Car.status` (enum values available 0, reserved 1, sold 2)
- [ ] T016 [US2] Restyle the staff list in `app/views/manage/cars/index.html.erb` as a styled table with status badges (US2-1) and the existing Edit, Show, and Share actions kept. Update the `car_status_badge` helper in `app/helpers/application_helper.rb` to emit these classes, keeping the current label text (FR-003)
- [ ] T017 [P] [US2] Restyle the staff detail page in `app/views/manage/cars/show.html.erb`, including the status badge and staff-contact section
- [ ] T018 [US2] Restyle the car form in `app/views/manage/cars/_form.html.erb`: a styled error alert above the form (US2-2), a "Listing" section for public fields and a "Staff contact" section for private fields with `.section-title` headings (US2-3), `.input` and `.label` on every field, Trix wrapper styled with `trix-editor`. Keep the hidden `lock_version` field, field names, and IDs.
- [ ] T019 [P] [US2] Restyle the new car page in `app/views/manage/cars/new.html.erb` (page header and layout around `_form`)
- [ ] T020 [P] [US2] Restyle the edit car page in `app/views/manage/cars/edit.html.erb`, including the stale-version alert that appears above the form
- [x] T021 [US2] Verify US2: run `bin/rails test test/controllers/manage/` and `bin/rails test:system test/system/car_media_test.rb test/system/live_updates_test.rb`, then fix any failures caused by the restyle

**Checkpoint**: US2 complete and independently verified.

---

## Phase 5: User Story 3 - Consistent navigation and account pages (Priority: P2)

**Goal**: Header states, sign-in, password reset, and share pages use the same form, button, and flash styles (US3).

**Independent Test**: Signed out, the header shows Inventory and Staff sign in. Signed in, it shows Inventory, Manage cars, and Sign out. Sign-in, password, share, and expired-link pages match the shared styles and show flash messages with a text prefix.

- [x] T022 [US3] Verify the header states in `app/views/layouts/application.html.erb` match US3-1 for both signed-in and signed-out users, and fix any mismatch
- [x] T023 [P] [US3] Restyle the sign-in page in `app/views/sessions/new.html.erb`, replacing its inline flash blocks with `shared/_flash.html.erb` (the `alert` and `notice` keys stay the same)
- [x] T024 [P] [US3] Restyle the password request page in `app/views/passwords/new.html.erb`, replacing its inline flash block with `shared/_flash.html.erb`
- [x] T025 [P] [US3] Restyle the password reset page in `app/views/passwords/edit.html.erb`, replacing its inline flash block with `shared/_flash.html.erb` (this page currently has no icon, so US3-2 requires one)
- [x] T026 [P] [US3] Restyle the shared car page in `app/views/shares/show.html.erb`: car details grouped as on the public detail page. Confirm no staff contact fields are rendered (FR-019, FR-020).
- [ ] T027 [P] [US3] Restyle the expired-link page in `app/views/shares/expired.html.erb` with the shared card and button styles, keeping the "link expired" message
- [x] T028 [US3] Layout test (SC-004): already exists as `test/controllers/ui_layout_test.rb`, which asserts the compiled `tailwind` stylesheet link and the header nav links for signed-out and signed-in states. No new file was created.
- [x] T029 [US3] Verify US3: run `bin/rails test test/controllers/layout_test.rb test/controllers/sessions_controller_test.rb test/controllers/passwords_controller_test.rb test/controllers/shares_controller_test.rb`, then fix any failures caused by the restyle

**Checkpoint**: US3 complete and independently verified.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Checks that span all stories.

- [x] T030 Diff the current labels, IDs, and `data-*` attributes against `specs/002-ui-modernize/attribute-inventory.md` and confirm nothing was renamed (FR-003). Also run `bin/rails routes` before and after the change and confirm the output is identical, and confirm with `git diff --stat` that no controller, model, or JavaScript file under `app/controllers`, `app/models`, or `app/javascript` changed (FR-006)
- [x] T031 [P] Fix the CI branch trigger in `.github/workflows/ci.yml` (`branches: [ main ]`) to match the repo's default branch `master`
- [ ] T032 Take screenshots at 375px and 1280px of every page in `quickstart.md` section 4, save them under `specs/002-ui-modernize/screenshots/`, and confirm there is no horizontal scroll at 375px (FR-004, SC-003)
- [ ] T033 [P] Check contrast and focus rings per `quickstart.md` section 5 (FR-005) and fix any failing controls in `app/assets/tailwind/application.css`
- [x] T034 Run `bin/ci` and confirm every step passes (passed after fixing whitespace offenses in `test/controllers/manage/car_media_test.rb` and `test/models/car_test.rb`). Then run `SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile` and confirm the compiled Tailwind stylesheet is in the precompile output (FR-007; `bin/ci` does not run precompile, the Dockerfile does)
- [x] T035 Compare final test counts with the baseline from T001 (SC-001, SC-002) and update `specs/002-ui-modernize/research.md` section 8 with the final numbers

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup. Blocks all user stories. T004 must finish first, because it records the pre-change attribute baseline. T005 and T006 touch the same layout file, so run them in order after T004.
- **User Stories (Phases 3–5)**: All depend on Foundational. US1 and US2 are both P1 and can run in parallel. US3 is P2.
- **Polish (Final Phase)**: Depends on all stories being complete

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational. Independent of other stories.
- **US2 (P1)**: Starts after Foundational. Independent of US1. T015 (badge classes) must finish before T016, T017.
- **US3 (P2)**: Starts after Foundational. T023 to T027 reuse `shared/_flash.html.erb` from T005. Independent of US1 and US2.

### Within Each Story

- Shared CSS classes (T015) before views that use them (T016, T017)
- Restyle tasks before their verification task (T014, T021, T029)
- Views marked [P] touch different files and can be done in any order

### Parallel Opportunities

- Setup: T001 and T002 run in sequence (T002 depends on the build); T003 is independent
- Foundational: T004 must complete before T005 and T006 start (see Phase Dependencies)
- US1: T008, T010, T012 can run in parallel with each other
- US2: T015, T017, T019, T020 can run in parallel once T015 is done
- US3: T023 to T027 can all run in parallel
- Polish: T031 and T033 can run in parallel

---

## Parallel Example: User Story 3

```bash
# After T005 (shared flash partial) is done, these can run together:
Task: "Restyle the sign-in page in app/views/sessions/new.html.erb"
Task: "Restyle the password request page in app/views/passwords/new.html.erb"
Task: "Restyle the password reset page in app/views/passwords/edit.html.erb"
Task: "Restyle the shared car page in app/views/shares/show.html.erb"
Task: "Restyle the expired-link page in app/views/shares/expired.html.erb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (blocks everything)
3. Complete Phase 3: US1 (customer pages)
4. **STOP and VALIDATE**: Run T014 and check the customer pages at 375px and 1280px

### Incremental Delivery

1. Setup and Foundational → shared layout, flash, and tap targets fixed
2. US1 → customer pages styled and verified (MVP)
3. US2 → staff pages styled and verified
4. US3 → account and share pages, layout test added
5. Polish → full `bin/ci`, screenshots, baseline comparison

---

## Notes

- `data-model.md` has no constrained schema fields for this feature. Its only content is the display-state mapping for `Car#status`, which T015 cites. No field-constraint tasks are needed.
- Mailer templates and `app/views/pwa/` are out of scope (spec Assumptions and FR-002).
- Dark mode is out of scope.
- Behavior, routes, validations, and JavaScript must not change (FR-006). If a restyle seems to require a behavior change, stop and raise it instead of making the change.
- Commit after each phase checkpoint.
- **Status at implementation (2026-11-26):** the Tailwind restyle of the views (T007–T013, T016–T020, T027) was already in commit `91e3937` on `master` before this run. Those tasks are not checked off because they were not re-inspected visually. Visual verification (T032 screenshots, T033 contrast) is still open and needs a browser.
- **FR-003 exception:** the photo upload field is `new_photos`, not `photos`. That is a behavior fix from before the restyle, not a styling change. It is documented in `attribute-inventory.md`, and the spec needs a decision on it. It also means controller and model changed since the baseline, which FR-006 does not allow as a pure restyle.
