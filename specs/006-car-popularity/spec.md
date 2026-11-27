# Feature Specification: Car Popularity by Favorites

**Feature Branch**: `feature/006-car-popularity`

**Created**: 2026-11-26

**Status**: Draft

**Input**: User description: "I need to know which cars are popular, as measured by the amount of favorites a car gets"

## Clarifications

### Session 2026-11-26

- Q: How should saves and removals of favorites reach the server so they can be counted? → A: Favorites move to the server, each tied to a random visitor identifier held by the visitor's browser (option B). This changes spec 001, US5, which kept favorites only in the browser.
- Q: Who should see the popularity ranking? → A: Staff only. Customers see no favorite counts (option A).
- Q: Over what time period should favorites be counted? → A: Staff choose the window: all-time or the last 30 days (option C).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See the most-favorited cars (Priority: P1)

A dealership manager wants to know which cars customers are interested in. They open a ranked list of cars by how many favorites each car has, most favorited first, and use it to decide which cars to feature, discount, or follow up on.

**Why this priority**: The ranking is the answer the manager asked for. Without favorite counts there is nothing to rank.

**Independent Test**: Save a favorite on three cars, two of them by different visitors, and remove one of them. Confirm the ranking lists the cars in the expected order with the expected counts.

**Acceptance Scenarios**:

1. **Given** cars with different numbers of favorites, **When** a staff member opens the popularity ranking, **Then** cars appear most favorited first, each with its favorite count.
2. **Given** a favorite that was saved and then removed, **When** the ranking is shown, **Then** that favorite no longer counts.
3. **Given** no car has any favorites, **When** the ranking is opened, **Then** a clear "No favorites yet" message is shown.
4. **Given** a car is marked sold or in transit, **When** the ranking is shown, **Then** the car still appears with its status, so the manager can see what customers were interested in.
5. **Given** the ranking, **When** the staff member chooses "last 30 days", **Then** only favorites saved in the last 30 days and still active are counted.

---

### Edge Cases

- A visitor saves and removes the same car repeatedly: that visitor counts at most once per car, and the count is never less than zero.
- Two cars tie on favorite count: they are listed in a stable order (by make and model).
- A car is deleted: its favorites are removed from the ranking.
- A visitor clears their browser storage: their random identifier is lost, so their saved favorites are no longer reachable from that browser.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each favorite MUST be stored on the server, linked to a random visitor identifier held by the visitor's browser. Each save and each removal MUST be recorded with its time (see Clarifications).
- **FR-002**: The system MUST NOT store a visitor's name, email address, or any other personal detail. The random identifier is the only identifier, and it is used only to hold that visitor's favorites.
- **FR-003**: Staff MUST be able to see a ranking of cars by favorite count, highest first, showing each car's count and status.
- **FR-004**: The popularity ranking MUST be visible to staff only. Customers MUST NOT see favorite counts or a most-favorited list.
- **FR-005**: The ranking MUST list cars in the same order for ties (by make and model), so the list is stable between views.
- **FR-006**: Staff MUST be able to choose the time window for the ranking: all time, or the last 30 days. Within a window, a car's count is the number of its favorites saved in that window that are still active.
- **FR-007**: A favorite count MUST update within one page load of a save or removal.
- **FR-008**: The favorites page MUST show the saved cars held on the server for the visitor's random identifier. Removing a favorite MUST leave it out of the favorites page and out of the counts.

### Key Entities

- **Favorite**: One visitor's saved car. Holds the car, the visitor's random identifier, the time it was saved, and the time it was removed (empty while active).
- **Car**: An existing vehicle. Its favorite count is the number of its active favorites (FR-006 narrows this by time window).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A staff member can find the most-favorited car in under 10 seconds.
- **SC-002**: 100% of favorite saves and removals are reflected in the ranking within one page load (FR-007).
- **SC-003**: No stored record holds a visitor's name, email address, or other personal detail, verified in 100% of tested records (FR-002).
- **SC-004**: No customer-facing page shows a favorite count or ranking, verified on every public page (FR-004).

## Assumptions

- A "favorite" is the existing save action on a car's page (spec 001, US5). Each visitor's favorite on a car counts once.
- Sold and in-transit cars stay in the ranking so the manager can see past interest (US1, scenario 4).
- Favorites now live on the server under the visitor's random identifier, so the favorites page reads from the server rather than only from the browser. This changes the spec 001, US5 rule that favorites live only in the browser.
- Clearing browser storage loses the random identifier, so the favorites under it can no longer be reached from that browser.

## Out of Scope

- Recommendations or "similar cars" based on favorites.
- Visitor accounts, sign-in, or contact details for customers (spec 001 keeps these out of scope).
- Customer-facing popularity signals (FR-004).
