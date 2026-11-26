# Tasks: Favorites Header Link

**Input**: Design documents from `/specs/005-favorites-header-link/`

**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Included. Constitution Principle II requires tests for the header link in both visitor states (FR-001, SC-002) and a test for the click (US1).

**Organization**: One user story (US1). The feature has no data or shared infrastructure, so there are no setup or foundational phases.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 (reach saved cars from any page, P1)

---

## Phase 1: User Story 1 - Reach saved cars from any page (Priority: P1) 🎯 MVP

**Goal**: Every visitor sees a "Favorites" link next to "Inventory" in the header, and it opens the favorites page (FR-001 to FR-004).

**Independent Test**: On the home page, click "Favorites" in the header and confirm the favorites page opens. Check the header for both a signed-out and a signed-in visitor.

### Tests for User Story 1

- [x] T001 [US1] Add header checks to `test/controllers/ui_layout_test.rb`: a signed-out page includes a "Favorites" link to `favorites_path` next to "Inventory"; a signed-in page includes it too, alongside "Inventory" and "Manage cars" (FR-001, FR-003, SC-002). Write these before T003.
- [x] T002 [P] [US1] Create `test/system/favorites_header_test.rb`: a visitor on the home page clicks "Favorites" in the header and lands on the favorites page (US1 scenario 2).

### Implementation for User Story 1

- [x] T003 [US1] Add the "Favorites" link in `app/views/layouts/application.html.erb` directly after the "Inventory" link, outside the `authenticated?` branch, so every visitor sees it. Use `favorites_path` and the same classes as "Inventory" (`inline-flex min-h-11 items-center rounded-lg px-3 py-2 text-slate-600 hover:bg-slate-100 hover:text-slate-900`) so the link is at least 44px tall (FR-001, FR-003, FR-004).

**Checkpoint**: The link appears for both visitor states and opens the favorites page.

### Verification for User Story 1

- [x] T004 [US1] Run `bin/rails test test/controllers/ui_layout_test.rb test/controllers/favorites_controller_test.rb` and `bin/rails test:system test/system/favorites_header_test.rb test/system/favorites_test.rb`. Confirm the favorites page behaves as before (FR-002).

---

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T005 Check the header at 375px width in Chrome's device mode: "Favorites" wraps with the other links and is at least 44px tall (quickstart section 3). This needs a browser, so it stays open until it is done.
- [x] T006 Run `bin/ci` and confirm every step passes.

---

## Dependencies & Execution Order

- T001 and T002 come before T003, so the tests fail first (Principle II).
- T002 is marked [P] because it is a different file from T001, and both can be written at the same time.
- T004 runs after T003. T005 and T006 come last.

## Implementation Strategy

### MVP (the whole feature)

1. Write T001 and T002.
2. Make T003.
3. Run T004. Then complete T005 and T006.

## Notes

- The link sits outside the `authenticated?` branch, so both visitor states see it.
- The header is outside the inventory's turbo frame, so the link is unaffected by the frame fix in feature 004.
