# Feature Specification: Favorites Header Link

**Feature Branch**: `feature/005-favorites-header-link`

**Created**: 2026-11-26

**Status**: Draft

**Input**: User description: "I can add a "Favorites" link to the header if you want one."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reach saved cars from any page (Priority: P1)

A customer who has saved cars wants to see them again. From any page, they click "Favorites" in the header and see their saved cars, without typing an address.

**Why this priority**: Saved cars are only useful if customers can find them. Today the only way is to know the address `/favorites`.

**Independent Test**: Save a car on its page, go to the home page, click "Favorites" in the header, and confirm the saved car is listed.

**Acceptance Scenarios**:

1. **Given** any page of the site, **When** a visitor looks at the header, **Then** a "Favorites" link is shown next to "Inventory".
2. **Given** a visitor who has saved cars in this browser, **When** they click "Favorites" in the header, **Then** their saved cars are listed.
3. **Given** a visitor with no saved cars, **When** they click "Favorites" in the header, **Then** the page shows the existing "You have no saved cars" message.
4. **Given** a visitor who is signed in as staff, **When** they look at the header, **Then** "Favorites" is shown alongside "Inventory" and "Manage cars".

---

### Edge Cases

- The browser blocks local storage: the header link still works, and the favorites page shows no saved cars (existing behavior).
- A narrow phone-width screen: the header link wraps with the other links and remains tappable at 44px or more.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The header MUST show a "Favorites" link for every visitor, whether or not they are signed in.
- **FR-002**: The "Favorites" link MUST go to the existing favorites page and MUST NOT change what that page shows.
- **FR-003**: The "Favorites" link MUST be placed next to "Inventory" in the header navigation.
- **FR-004**: The "Favorites" link MUST be at least 44px tall on phone-width screens, like the other header links (spec 002, US3-3).
- **FR-005**: The header link MUST NOT show a count of saved cars in this version.

### Key Entities

None. This feature adds a link only. Saved cars already exist in the browser (spec 001, US5).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A visitor can reach their saved cars from any page in one click.
- **SC-002**: The "Favorites" link appears on 100% of pages, for both signed-in and signed-out visitors.
- **SC-003**: The "Favorites" link is at least 44px tall at a 375px-wide screen.

## Assumptions

- The label is exactly "Favorites", matching the existing page title "Saved cars" in the page heading.
- No change to how favorites are stored or shown on the favorites page (spec 001, US5).
- The link is placed in the same header navigation as "Inventory" and "Manage cars".

## Out of Scope

- A saved-cars count or badge in the header.
- Changes to the favorites page itself.
- Changes to how favorites are saved or stored.
