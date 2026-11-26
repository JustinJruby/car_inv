# Research: Modern UI with Tailwind CSS

Each decision below resolves an open question from the plan's Technical Context. No NEEDS CLARIFICATION items remain.

## 1. How Tailwind is delivered

**Decision**: Use the `tailwindcss-rails` gem (4.7.0), which bundles the standalone Tailwind CLI through `tailwindcss-ruby`.

**Rationale**: FR-001 requires Tailwind. The gem runs the build with no Node toolchain, which matches the existing importmap setup (no npm). The build hooks into `assets:precompile`, so the production Dockerfile (`RUN ./bin/rails assets:precompile`) produces the stylesheet without extra steps (FR-007).

**Alternatives considered**:
- `cdn.tailwindcss.com` script tag: rejected. It is a development-only CDN build that generates CSS in the browser, and it is not suitable for production.
- `tailwindcss` via npm with `jsbundling-rails`: rejected. It adds a Node build step the app does not otherwise need.
- Hand-written CSS: rejected. It does not meet FR-001.

## 2. Gem budget

**Decision**: Accept a third gem (`tailwindcss-rails`) on top of `bcrypt` and `image_processing`.

**Rationale**: The spec requires it. The 001 plan's two-gem limit was a rule for that feature's scope, not a standing project rule. The constitution's Simplicity principle is met because the gem is justified by a current requirement (FR-001).

**Alternatives considered**: None that meet FR-001 without Node.

## 3. Where shared styling lives

**Decision**: Keep the component classes (`.btn-primary`, `.btn-secondary`, `.btn-danger`, `.input`, `.label`, `.card`, `.badge`, `.chip`, `.section-title`, `trix-editor`) in `app/assets/tailwind/application.css` under `@layer components`. Views use these classes instead of repeating long utility strings.

**Rationale**: About 25 views share the same controls, and one definition per pattern keeps the restyle consistent. `@layer components` lets views override a class with a utility when needed.

**Alternatives considered**:
- Utility classes only, repeated in each view: rejected. Consistency would depend on copy-paste across 25 files.
- ViewComponent or a helper for each control: rejected. A new dependency or abstraction with no current requirement behind it (Principle III).

## 4. Tap target size (US3-3, 44px)

**Decision**: Set a minimum height of 44px (`min-h-11`) on interactive controls in the header and in the `.btn-*` base classes.

**Rationale**: The current nav links (`py-2 text-sm`) render about 36px. Setting the minimum height keeps the visual size compact while meeting the spec.

**Alternatives considered**: Increase padding only. Rejected because the rendered height depends on line height, so `min-h` is more predictable.

## 5. Dev-mode CSS rebuilds

**Decision**: Document `bin/rails tailwindcss:watch` in `quickstart.md`. Do not add a `Procfile.dev`.

**Rationale**: `bin/dev` only runs `rails server`. A watcher is needed in development, but adding `foreman` and a Procfile for one process is an unjustified dependency (Principle III).

**Alternatives considered**: Add `foreman` with `Procfile.dev` (the generator default). Deferred. Revisit if more dev processes are added.

## 6. Flash messages

**Decision**: One partial, `app/views/shared/_flash.html.erb`, renders `notice` (emerald, check icon) and `alert` (red, "!" icon) with `role="status"` and `role="alert"`.

**Rationale**: The current flash markup is duplicated in four places and has already drifted. The icon satisfies US3-2 (distinguishable without color alone).

**Alternatives considered**: Leave the duplicates. Rejected because the drift will get worse during restyling.

## 7. Verifying "no behavior change" (FR-003, FR-006)

**Decision**: Before each view is restyled, record its labels, IDs, and `data-*` attributes. After restyling, compare them and confirm the existing test suite passes.

**Rationale**: The existing controller and system tests check text and form fields, so they catch most accidental renames. The diff catches the rest, such as `data-` hooks used by Stimulus.

**Alternatives considered**: Rely on tests alone. Rejected because some Stimulus hooks are not covered by assertions.

## 8. Baseline test counts

**Decision**: Measure the real baseline in Phase 0 with `bin/rails test` and `bin/rails test:system`, and record the numbers in this file. Do not use the 65 + 6 figures from the spec until they are confirmed.

**Rationale**: A search of `test/` finds about 74 `test "` blocks in total, and 6 in `test/system`. That leaves about 68 non-system tests, not 65. The spec's counts may be stale, so the measured numbers should be the ones SC-001 and SC-002 check against.

**Baseline** (measured on `master` before any view changes, 2026-11-26):
- `bin/rails test`: 68 runs, 228 assertions, 0 failures, 0 errors, 0 skips
- `bin/rails test:system`: 6 runs, 22 assertions, 0 failures, 0 errors, 0 skips

The spec's SC-001 figure of 65 is replaced with 68 (see spec.md SC-001).

**Final, after the restyle fixes and `bin/ci` run (2026-11-26):** unit tests unchanged at 68 runs, 228 assertions, 0 failures. System tests unchanged at 6 runs, 22 assertions, 0 failures. `bin/ci` passes all steps.
