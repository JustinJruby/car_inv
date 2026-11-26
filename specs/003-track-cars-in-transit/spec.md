# Feature Specification: Track Cars in Transit

**Feature Branch**: `feature/003-track-cars-in-transit`

**Created**: 2026-11-26

**Status**: Draft

**Input**: User description: "I want to be able to track cars in transit to my dealership"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record a car on its way (Priority: P1)

A dealership manager is told that a car is coming to their lot. They record the car's VIN, where it is coming from, and when it is expected to arrive, so the team knows it exists before it physically shows up.

**Why this priority**: Without a record of inbound cars, staff cannot plan for them, quote them, or see them coming. Every other transit capability depends on this record.

**Independent Test**: As a staff member, record a car that is on its way, then confirm it appears in the in-transit list with the origin and expected arrival date entered.

**Acceptance Scenarios**:

1. **Given** a signed-in staff member, **When** they record a car in transit with a VIN, origin, and expected arrival date, **Then** the car appears in the in-transit list.
2. **Given** a car already in transit to this dealership, **When** staff try to record another open transit for the same VIN, **Then** the system rejects it and says a transit is already open for that car.
3. **Given** a transit form with a missing origin or expected arrival date, **When** staff submit it, **Then** the transit is not saved and staff are told which field is missing.

---

### User Story 2 - See what is arriving and what is late (Priority: P1)

A manager opens the in-transit list to see every car heading to any dealership in the group, sorted by expected arrival, and sees which ones are already past their expected arrival date.

**Why this priority**: The list is what makes the record useful. Overdue cars are the ones staff need to chase.

**Independent Test**: Record three in-transit cars with different expected arrival dates, one of them in the past. Open the list and confirm the order is by expected arrival and the past-due car is flagged.

**Acceptance Scenarios**:

1. **Given** several cars in transit to this dealership, **When** a staff member opens the in-transit list, **Then** the cars are listed by expected arrival date, earliest first.
2. **Given** a car whose expected arrival date has passed and is not yet marked arrived, **When** the list is shown, **Then** that car is visibly flagged as overdue.
3. **Given** no cars in transit to this dealership, **When** the list is opened, **Then** a clear "No cars are in transit" message is shown.

---

### User Story 3 - Mark arrivals, cancellations, and date changes (Priority: P2)

When a car arrives, staff mark it arrived. The car then counts as stock at the dealership and the transit closes. Staff can also cancel a transit or change its expected arrival date, and each change is kept in the transit's history.

**Why this priority**: Arrival is the point where a transit becomes ordinary inventory. Without it the list goes stale. Cancellations and date changes keep the list accurate but are less frequent.

**Independent Test**: Record a transit, change its expected arrival date, mark it arrived, and confirm the car is now in dealership inventory and the transit no longer appears in the in-transit list. Confirm the history lists each change.

**Acceptance Scenarios**:

1. **Given** an open transit, **When** staff mark it arrived, **Then** the car appears in the dealership's inventory and the transit is removed from the in-transit list.
2. **Given** an open transit, **When** staff cancel it, **Then** it is removed from the in-transit list and the car's record is unchanged.
3. **Given** an open transit, **When** staff change its expected arrival date, **Then** the new date is shown and the change is recorded in the transit's history with the staff member's name and time.

---

### User Story 4 - Pre-sell a car that is still in transit (Priority: P2)

A manager has a car on its way that they want to offer before it arrives. They mark the transit for pre-sell and set a price. Customers then see the car in the public inventory with its price and expected arrival, labeled as a pre-sell. When the car arrives, it becomes a normal listing at the same price.

**Why this priority**: This is the reason for tracking in-transit cars for this business: selling before the car lands. It depends on the transit record in User Story 1, so it follows the core tracking work.

**Independent Test**: Record an in-transit car, mark it for pre-sell with a price, and confirm a customer sees it in the public inventory with the price and the expected arrival date. Then mark it arrived and confirm it is listed as a normal car at the same price.

**Acceptance Scenarios**:

1. **Given** an open transit, **When** staff mark it for pre-sell and set a price, **Then** the car appears in the public inventory labeled as a pre-sell, showing the price and expected arrival date.
2. **Given** an open transit marked for pre-sell, **When** staff change the pre-sell price, **Then** customers see the new price the next time they view the car.
3. **Given** an open transit that is not marked for pre-sell, **When** a customer browses the public inventory, **Then** the car does not appear.
4. **Given** a pre-sell car, **When** the transit is marked arrived, **Then** the car is listed as a normal available car at the pre-sell price, and the pre-sell label is removed.
5. **Given** a pre-sell car, **When** the transit is cancelled, **Then** the car is removed from the public inventory.

---

### Edge Cases

- A car with a VIN that is already in inventory or in transit (not sold) cannot be recorded as in transit: the system rejects the transit and says the car already exists. A sold car's VIN may be recorded again, as the VIN rule allows.
- An expected arrival date in the past is entered when the transit is recorded: the system must accept it and flag the transit as overdue right away.
- A transit is marked arrived after the car was already marked sold: the car stays sold and the arrival is still recorded in history.
- Two staff members mark the same transit arrived at the same time: only one arrival is recorded, and the second staff member sees the transit is already closed.
- A transit is cancelled after staff have already started a related sale: the sale is not changed automatically, and the transit history shows the cancellation.
- A transit is marked for pre-sell without a price: the car stays hidden from customers until a price is set.
- A customer has saved a pre-sell car as a favorite, and the car is later removed from the public inventory: the favorite shows the car as unavailable, as it does for other removed cars.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Signed-in staff MUST be able to record a car as in transit, giving the car's VIN, make, model, year, its origin, and its expected arrival date. Mileage and asking price are required once the car is marked arrived or pre-sold.
- **FR-002**: The system MUST allow at most one open transit per car at any time.
- **FR-003**: Staff MUST be able to see all open transits across all dealerships, ordered by expected arrival date with the earliest first.
- **FR-004**: The system MUST flag any open transit whose expected arrival date has passed as overdue.
- **FR-005**: Staff MUST be able to mark an open transit as arrived. Arrival MUST make the car part of the dealership's inventory and close the transit.
- **FR-006**: Staff MUST be able to cancel an open transit. Cancellation MUST NOT change the car's own record.
- **FR-007**: Staff MUST be able to change an open transit's expected arrival date.
- **FR-008**: The system MUST keep a history of every transit change (recorded, date changed, pre-sell set or changed, arrived, cancelled), with the staff member who made it and the time.
- **FR-009**: Transit origin, expected arrival dates, and transit history MUST NOT be visible to customers or to anyone without a staff sign-in.
- **FR-010**: Any car may be tracked as in transit, whatever its source: a purchase from an outside seller, an auction, or another location in the group.
- **FR-011**: Staff MUST be able to mark an open transit for pre-sell and set a pre-sell price. Only transits marked for pre-sell with a price are shown to customers.
- **FR-012**: A pre-sell car MUST appear in the public inventory labeled as a pre-sell, showing its pre-sell price and expected arrival date. It MUST NOT show its origin.
- **FR-013**: Changes to a pre-sell price MUST be visible to customers as soon as staff save them.
- **FR-014**: When a pre-sell transit arrives, the car MUST become a normal available listing at the pre-sell price, and the pre-sell label MUST be removed.
- **FR-015**: When a pre-sell transit is cancelled, the car MUST be removed from the public inventory.

### Key Entities

- **Car**: An existing vehicle in the inventory, identified by VIN. A transit does not change the car's own details, except that arrival adds the car to dealership inventory and gives it the pre-sell price as its asking price.
- **Transit**: One trip of a car to a dealership. Holds the car, the destination dealership, the origin, the expected arrival date, its current state (open, arrived, or cancelled), whether it is marked for pre-sell, the pre-sell price, and the history of its changes.
- **Transit history entry**: One recorded change to a transit: what changed, the previous and new values where relevant, the staff member, and the time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A staff member can record a car in transit in under 1 minute.
- **SC-002**: 100% of open transits whose expected arrival date has passed are flagged as overdue in the in-transit list.
- **SC-003**: A staff member can find a specific in-transit car by VIN in under 10 seconds.
- **SC-004**: Marking a transit arrived makes the car appear in dealership inventory without any separate data entry.
- **SC-005**: No car ever has two open transits at the same time, in every tested sequence of record, change, and arrival actions.
- **SC-006**: Every transit change is visible in its history, with the staff member and time, for 100% of changes.
- **SC-007**: 100% of transits without a pre-sell price, and 100% of transits not marked for pre-sell, are absent from the public inventory.
- **SC-008**: A customer sees a newly saved pre-sell price on the car's public page on their next page load.

## Assumptions

- Each car belongs to one dealership at a time. For an inbound car, the destination is the dealership that recorded the transit.
- **Known gap (decided, option B)**: every signed-in staff member sees and changes transits for all dealerships in this version. Staff accounts are not linked to a dealership, so staff are not limited to their own dealership's transits. Scoping staff to their own dealership is a follow-up feature.
- Transit status is updated by hand by staff. This feature does not connect to carriers, shipping companies, or location tracking.
- Origin, expected arrival dates, and transit history stay private (FR-009). Customers see only the pre-sell price and expected arrival date for a pre-sell car.
- Overdue is based on the expected arrival date only; no reminder emails are sent in this feature.
- The pre-sell price is stored on the transit, not on the car, until arrival. On arrival it becomes the car's asking price.
- A price reduction on a pre-sell car follows the same favorites rules as any other price reduction.
- Customers cannot pay, place a deposit, or buy through the app in this feature. Customers can see and save a pre-sell car as a favorite. Orders and deposits happen offline with staff, and no contact channel is added in this feature (decided, option A).

## Out of Scope

- Carrier, shipping, or GPS integration.
- Notifications or emails about transits.
- Transit cost, freight billing, or paperwork such as bills of lading.
- Online payment, deposits, or checkout for pre-sell cars.
- Changes to how cars are priced or sold after they arrive.
