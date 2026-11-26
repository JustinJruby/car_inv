# Implementation Plan: Modern UI with Tailwind CSS

**Branch**: `002-ui-modernize` | **Date**: 2026-11-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-ui-modernize/spec.md`

## Summary

Restyle every page in the Rails app with Tailwind CSS, delivered through the `tailwindcss-rails` gem (standalone CLI, no Node build step). No behavior, route, data, or JavaScript changes (FR-006). Part of the work is already in the working tree: the gem is in the Gemfile, `app/assets/tailwind/application.css` defines the shared component classes, and the layout loads the compiled `tailwind` stylesheet. The remaining work is to restyle the 25 views in `app/views`, close the gaps found in review (the 44px tap targets, the dev-mode CSS watcher, the duplicated flash markup), add the layout test (SC-004), and record the verified baseline test counts.

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.4.1

**Primary Dependencies**: `tailwindcss-rails` 4.7.0 (uses `tailwindcss-ruby` 4.3.4, a standalone binary), existing Rails stack (Turbo, Stimulus, importmap, Propshaft, Action Text/Trix)

**Storage**: N/A. No schema changes.

**Testing**: Minitest. `bin/rails test` for unit and controller tests, `bin/rails test:system` for system tests (headless Chrome). Visual checks at 375px and 1280px (SC-003).

**Target Platform**: Modern desktop and mobile browsers, from 375px width up.

**Project Type**: Web application (server-rendered Rails with Hotwire).

**Performance Goals**: No regression in page load. The compiled stylesheet is a single file, `app/assets/builds/tailwind.css` (about 30 KB in the working tree).

**Constraints**:
- FR-003: keep existing labels, button names, field names and IDs, `data-*` attributes, Turbo frame/stream IDs, and Stimulus hooks.
- FR-004: no horizontal page scroll at 375px.
- FR-005: WCAG AA contrast and visible focus states.
- FR-007: compiled CSS must be present in production builds.
- Spec acceptance (US3-3): controls at least 44px tall.

**Scale/Scope**: 25 ERB templates across layouts, cars, favorites, sessions, passwords, shares, and manage/cars. Mailer templates are out of scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Spec Before Code | `spec.md` exists with user stories, requirements, and success criteria. | PASS. Principle I was amended (v1.0.1) to say specs live in `specs/<feature>/`, which matches where spec-kit writes them. |
| II. Test-Backed Changes | SC-004 requires a test for the layout (stylesheet link and nav links). Restyle work is verified by the existing suites, measured as 68 unit tests and 6 system tests (both passing before any change; see `research.md` section 8), which must still pass (SC-001, SC-002). | PASS, with the layout test added in Phase 4. |
| III. Simplicity First | `tailwindcss-rails` is required by FR-001. No Node toolchain, no CDN script, no other CSS framework. Shared patterns use `@layer components` classes (`.btn-*`, `.input`, `.card`, `.badge`) instead of new view helpers. | PASS. This adds a third gem. The 001 plan allowed only two, and that limit does not carry over. The reason is recorded in `research.md`. |
| IV. Small, Reviewable Changes | Split into four phases (below), each leaving the app working and tested. | PASS |
| V. Decisions Are Recorded | Tailwind delivery, component-class approach, tap-target fix, and watcher approach are in `research.md`. | PASS |

**Quality gates**: The constitution requires PR review on `main`. The repo's default branch is `master`, and `.github/workflows/ci.yml` targets `main`. The feature should merge through a PR into the default branch, and the CI branch name should be fixed (see Phase 4).

**Result**: No violations. Complexity Tracking stays empty.

## Phases

Each phase leaves `bin/rails test` and `bin/rails test:system` green.

| Phase | Scope | Exit check |
|-------|-------|------------|
| 0. Baseline and foundation | Measure the real test baseline. Confirm the Tailwind build runs (`bin/rails tailwindcss:build`) and the compiled CSS is loaded. Add the dev watcher docs. | Baseline numbers recorded. Build succeeds. |
| 1. Customer pages | `cars/index`, `_car`, `_results`, `_gallery`, `show`, `favorites/index`. Header, filter panel, card grid, detail page, "Save to favorites" as primary button. | US1 acceptance met. Existing system tests pass (favorites, price badge, car media). |
| 2. Staff pages | `manage/cars/*` (index table with status badges, form with sections and error alert), Trix wrapper. | US2 acceptance met. Existing controller and system tests pass. |
| 3. Account and share pages | `sessions/new`, `passwords/new`, `passwords/edit`, `shares/show`, `shares/expired`. Unify flash markup into one partial. | US3 acceptance met. |
| 4. Verification | Add the layout test (SC-004). Fix the CI branch trigger. Screenshot pass at 375px and 1280px. Full `bin/ci`. | SC-001 to SC-004 met. |

### Cross-cutting fixes found during planning

1. **Tap targets (US3-3).** The header nav links and the "Staff sign in" and "Sign out" buttons use `py-2 text-sm`, which renders about 36px tall. Give them `min-h-11` (44px) and keep the padding. The fix goes in the layout and in the `.btn-*` base classes.
2. **Dev CSS watcher.** `bin/dev` only runs `rails server`. There is no `Procfile.dev`, so edits to Tailwind classes will not rebuild the CSS in development. Decision: document `bin/rails tailwindcss:watch` in `quickstart.md` and run it in a second terminal. Adding `foreman` and a `Procfile.dev` would be a new dependency for a single watcher, so it is not justified yet (Principle III).
3. **Duplicated flash markup.** The layout, `sessions/new`, `passwords/new`, and `passwords/edit` each render their own flash block, and the markup has drifted (for example, `passwords/edit` has no icon). Extract `app/views/shared/_flash.html.erb` and render it from the layout and the account pages. This satisfies US3-2 (icon or text prefix, not color alone).
4. **Spec-vs-code label check (FR-003).** Before restyling any view, record its existing labels, IDs, and `data-*` attributes. After restyling, diff them to confirm nothing was renamed.

## Project Structure

### Documentation (this feature)

```text
specs/002-ui-modernize/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # No data changes
├── attribute-inventory.md  # FR-003 baseline of labels, IDs, data-* attributes (created in T004)
└── quickstart.md        # Validation and run guide
```

No `contracts/` directory. The spec adds no routes, endpoints, or external interfaces (FR-006), so there is nothing to contract.

### Source Code (repository root)

```text
app/assets/tailwind/application.css   # Tailwind entry: @import, @source, @layer components classes
app/assets/builds/tailwind.css        # Generated by tailwindcss-rails (gitignored; built in precompile)
app/views/
├── layouts/application.html.erb      # Shared header, nav, flash (Phase 0, 1, 3)
├── shared/_flash.html.erb            # NEW: single flash partial (Phase 3)
├── cars/                             # index, _car, _results, _gallery, show (Phase 1)
├── favorites/index.html.erb          # Phase 1
├── manage/cars/                      # index, new, edit, show, _form (Phase 2)
├── sessions/new.html.erb             # Phase 3
├── passwords/new.html.erb, edit.html.erb   # Phase 3
└── shares/show.html.erb, expired.html.erb  # Phase 3
test/
└── controllers/layout_test.rb        # NEW: SC-004 (stylesheet link, nav links per auth state)
config/ci.rb, .github/workflows/ci.yml  # Phase 4: fix branch trigger (main vs master)
```

**Structure Decision**: Single Rails app, no new directories beyond `app/views/shared/` and one new test file. Styling stays in the existing Tailwind entry file, with component classes for patterns that repeat across views.

## Complexity Tracking

> Empty. No Constitution Check violations.
