# Implementation Plan: Favorites Header Link

**Branch**: `feature/005-favorites-header-link` | **Date**: 2026-11-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-favorites-header-link/spec.md`

## Summary

Add a "Favorites" link to the site header, next to "Inventory", for every visitor. It goes to the existing favorites page at `/favorites` and changes nothing else. The header already has a navigation list with a consistent link style and a 44px tap-target rule (spec 002, US3-3), so the new link follows that pattern. The change is one line in the layout plus a test.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.4.1

**Primary Dependencies**: None added. Existing Rails layout, Tailwind component classes.

**Storage**: N/A. Favorites stay in browser local storage as they do today (spec 001, US5).

**Testing**: Minitest. A controller/integration test for the header link, and one system test for clicking it.

**Target Platform**: Web, desktop and phone-width browsers.

**Project Type**: Web application (server-rendered Rails with Hotwire).

**Performance Goals**: None beyond the current page. The link is static markup.

**Constraints**:
- FR-001: shown to signed-in and signed-out visitors.
- FR-004 and SC-003: at least 44px tall at 375px.
- FR-005: no saved-car count in the header.

**Scale/Scope**: One link in one layout file.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Spec Before Code | `spec.md` exists in `specs/005-favorites-header-link/`, with user stories, requirements, and success criteria. | PASS |
| II. Test-Backed Changes | The link gets a test for each visitor state (FR-001, SC-002) and a system test for the click (US1). | PASS |
| III. Simplicity First | One link, no new gem, no new route, no new JavaScript. The existing `/favorites` page is reused. | PASS |
| IV. Small, Reviewable Changes | One phase, one layout change and its tests. | PASS |
| V. Decisions Are Recorded | The placement and label are recorded in `research.md`. | PASS |

**Result**: No violations. Complexity Tracking stays empty.

## Phases

| Phase | Scope | Exit check |
|-------|-------|------------|
| 1. Link and tests | Add the "Favorites" link to `app/views/layouts/application.html.erb` next to "Inventory", with the header's link classes. Add tests for signed-out and signed-in visitors. Add a system test that clicks the link. | Layout tests and the system test pass. `bin/ci` passes. |

## Project Structure

### Documentation (this feature)

```text
specs/005-favorites-header-link/
├── spec.md
├── plan.md              # This file
├── research.md          # Placement decision
├── quickstart.md        # Validation guide
└── checklists/requirements.md
```

No `data-model.md`: the spec has no entities. No `contracts/`: the feature adds no interface.

### Source Code (repository root)

```text
app/views/layouts/application.html.erb   # CHANGED: Favorites link in the header navigation
test/controllers/ui_layout_test.rb       # CHANGED: link present for signed-out and signed-in visitors
test/system/favorites_header_test.rb     # NEW: click the link from the home page
```

**Structure Decision**: Single Rails app. The change stays in the existing layout and the existing layout test file, so no new structure is needed.

## Route Surface

No new routes. The link points to the existing `GET /favorites`.

## Cross-cutting notes

1. **Tap target.** The link uses the same `min-h-11` classes as "Inventory" and "Manage cars", so it meets the 44px rule (FR-004).
2. **Signed-out and signed-in.** The link sits outside the `authenticated?` branch, so both states show it (FR-001).
3. **Turbo frame.** The header is outside the inventory's turbo frame, so the link is not affected by the frame issue fixed in feature 004.
