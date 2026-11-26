# Feature Specification: Modern UI with Tailwind CSS

**Feature Branch**: `claude/changes`
**Created**: 2026-11-26
**Status**: Draft
**Input**: User description: "Update the UI of all pages to look modern and keep Tailwind CSS."

## Problem

Every page is unstyled HTML: plain links separated by pipes, default form controls, and an unstyled table. The app looks unfinished to both customers and staff. The request is to give all pages a modern look using Tailwind CSS. The project does not yet include Tailwind, so it must be added.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Customers browse with a modern layout (Priority: P1)

A customer sees a clean header, a filter panel with styled inputs, and car cards in a responsive grid that they can scan quickly. The car detail page shows the photo gallery, key facts, and a clear save button.

**Acceptance Scenarios**:
1. **Given** the inventory page, **When** it loads, **Then** cars appear as cards in a grid (3+ columns at 1024px and wider, 1 column on phones), each showing year, make, model, price, and features.
2. **Given** no cars match, **When** the customer searches, **Then** a styled empty-state message says "No cars match these filters."
3. **Given** the car detail page, **When** it loads, **Then** the title, price, mileage, features, and description are visually grouped, and "Save to favorites" is a visible primary button.

### User Story 2 - Staff manage cars efficiently (Priority: P1)

A signed-in staff member sees the car list as a styled table with status badges, and the add/edit form as a clearly sectioned, styled form with visible field errors.

**Acceptance Scenarios**:
1. **Given** the manage list, **When** it loads, **Then** status is shown as a colored badge (available, reserved, sold).
2. **Given** the car form, **When** validation fails, **Then** errors appear in a styled alert above the form.
3. **Given** the car form, **When** it loads, **Then** public and private (staff contact) fields are in separate, labeled sections.

### User Story 3 - Consistent navigation and account pages (Priority: P2)

Every page shares one header with navigation, the sign-in, password-reset, saved-cars, and share-link pages use the same form and button styles, and flash notices and alerts are styled consistently.

**Acceptance Scenarios**:
1. **Given** any page, **When** a user is signed in, **Then** the header shows Inventory, Manage cars, and Sign out; when signed out it shows Inventory and Staff sign in.
2. **Given** a flash notice or alert, **When** it is shown, **Then** it uses a success or error style that is distinguishable without relying on color alone (icon or text prefix).
3. **Given** a phone-width screen, **When** any page loads, **Then** nothing overflows horizontally and all controls are at least 44px tall.

## Requirements *(mandatory)*

- **FR-001**: The app MUST use Tailwind CSS (`tailwindcss-rails`) for all page styling; no other CSS framework is added.
- **FR-002**: Every page listed in `app/views` (layouts, cars, car detail, favorites, sessions, passwords, shares, manage cars, mailers excluded) MUST be restyled.
- **FR-003**: All existing text labels, button names, form field names and IDs, `data-*` attributes, Turbo frame and stream IDs, and Stimulus controller hooks MUST be preserved, so behavior and existing tests keep working.
- **FR-004**: Layout MUST be responsive: usable from 375px width up to desktop, with no horizontal page scroll.
- **FR-005**: Color contrast MUST meet WCAG AA for text and interactive controls, and focus states MUST be visible.
- **FR-006**: No behavior changes: no new routes, fields, validations, or JavaScript features.
- **FR-007**: Tailwind classes MUST be compiled into the app's stylesheet build, so the styles are present in production builds.

## Success Criteria *(mandatory)*

- **SC-001**: `bin/rails test` passes with the same 68 tests (228 assertions) as before the change (no test edited to make it pass, except where a spec-driven text change is noted in the plan).
- **SC-002**: `bin/rails test:system` passes with the same 6 tests.
- **SC-003**: Screenshots at 375px and 1280px show every page rendering with Tailwind styles and no unstyled default elements.
- **SC-004**: Add a test asserting that the layout includes the compiled stylesheet and the header navigation links.

## Assumptions

- The user's phrase "keep Tailwind CSS" is taken to mean Tailwind should be used. It was not present in the repo, so it is added via the `tailwindcss-rails` gem (standalone CLI, no Node build step).
- Dark mode is out of scope.
- Brand colors: a neutral slate base with one indigo accent. No logo change.
- Mailer templates are out of scope (email clients handle their own styling).

## Out of Scope

- Changing data, routes, controllers' behavior, or Turbo/Stimulus logic.
- Redesigning the Trix rich-text editor internals (only its wrapper is styled).
