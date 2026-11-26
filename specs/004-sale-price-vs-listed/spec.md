# Feature Specification: Sale Price vs Listed Price

**Feature Branch**: `feature/004-sale-price-vs-listed`

**Created**: 2026-11-26

**Status**: Draft

**Input**: User description: "we need to record selling price vs listed price"

## Clarifications

### Session 2026-11-26

- Q: Which listed price should the difference use: the asking price at the moment the car sold, the first price the car was listed at, or both shown side by side? → A: Display both side by side (option C). The difference is measured against the asking price at the moment of sale.
- Q: What should the internal price represent: the amount the dealership paid for the car, the lowest price management will accept, or something else? → A: Dealer cost, the amount the dealership paid for the car (option A). It is recorded for staff only and no margin is calculated in this feature.
- Q: How should sold cars recorded before this feature, which have no sale price, be handled: left blank, or flagged for staff to fill in? → A: Before any such car can be edited, staff must enter its sale price (option C).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record the selling price when a car is sold (Priority: P1)

When a staff member marks a car as sold, they enter the price it sold for. The car keeps that sale price, so the dealership knows what each car actually brought in.

**Why this priority**: Without a recorded sale price, the dealership cannot compare what it asked with what it got. Every other part of this feature depends on it.

**Independent Test**: Mark a listed car as sold, enter a sale price, and confirm the car shows the sale price and the sale date.

**Acceptance Scenarios**:

1. **Given** a signed-in staff member and an available car, **When** they mark the car sold with a sale price, **Then** the car is sold, its sale price and sale date are saved, and the staff member's name and time are recorded in its history.
2. **Given** a staff member marking a car sold, **When** they leave the sale price empty or enter zero or a negative amount, **Then** the car is not marked sold and staff are told the sale price is required.
3. **Given** a car already marked sold, **When** staff correct its sale price, **Then** the new price replaces the old one and both prices are kept in the history.

---

### User Story 2 - See the difference between listed and sale price (Priority: P1)

For each sold car, staff see its listed price, its sale price, and the difference between them, as an amount and as a percentage of the listed price.

**Why this priority**: The difference is the reason for recording both prices. Staff use it to see how much a car was discounted or sold above its price.

**Independent Test**: Sell a car listed at $20,000 for $19,000. Confirm the car shows a difference of $1,000 below listed, or 5% below.

**Acceptance Scenarios**:

1. **Given** a sold car with a listed price and a sale price, **When** staff view the car, **Then** the listed price, sale price, and difference are shown, with the difference labeled as below or above listed.
2. **Given** a sold car whose sale price equals its listed price, **When** staff view the car, **Then** the difference is shown as zero.
3. **Given** a sold car with no listed price on record, **When** staff view the car, **Then** the difference is shown as "not available" rather than an error or zero.

---

### User Story 3 - Report on sales against listed price (Priority: P2)

Staff can see every car sold in a chosen date range, with its listed price, sale price, and difference, and totals for the period.

**Why this priority**: A single car's difference is useful. The period report shows whether the dealership is discounting too much overall. It is less urgent than recording the price.

**Independent Test**: Sell three cars in a week with known prices. Run the report for that week and confirm each row and the totals match.

**Acceptance Scenarios**:

1. **Given** cars sold within a date range, **When** staff run the report for that range, **Then** each car appears once with its listed price, sale price, and difference, and the report shows the total listed, total sold, and total difference.
2. **Given** no cars sold in the range, **When** staff run the report, **Then** a clear "No sales in this period" message is shown.
3. **Given** cars sold outside the range, **When** staff run the report, **Then** they do not appear.

---

### Edge Cases

- A car's listed price changes several times before it sells: the listed price used is the one set at the moment it was sold.
- A car is marked sold, then its status is changed to available again: the sale price is kept in the history and removed from the car, so the car is not counted as sold.
- A sale price is entered with more than two decimal places: the system rejects it and says the price must be in dollars and cents.
- A sold car is edited to change its listed price after the sale: the sale price and the recorded difference stay as they were at the sale, and the history shows the change.
- A sold car recorded before this feature is opened for editing without a sale price: the edit is not saved until the sale price is entered, and staff are told the sale price is required first.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Staff MUST enter a sale price when marking a car sold. The sale is not saved without it.
- **FR-002**: A sale price MUST be greater than zero and expressed in dollars and cents.
- **FR-003**: The system MUST record the date a car was marked sold, and the staff member who marked it.
- **FR-004**: The system MUST show, for each sold car, the asking price at the moment of sale and the first price the car was listed at, side by side, together with the sale price. The difference is measured against the asking price at the moment of sale, as an amount and as a percentage of that price.
- **FR-005**: The system MUST label the difference as below listed, above listed, or equal to listed.
- **FR-006**: Staff MUST be able to correct a sale price after a car is sold. Every correction MUST be kept in the car's history with the staff member and time.
- **FR-007**: When a sold car's status is changed to another status, the sale price MUST be removed from the car and kept in its history.
- **FR-008**: Staff MUST be able to report on sold cars within a chosen date range, showing each car's listed price, sale price, and difference, with totals for the range.
- **FR-009**: Sale prices, dealer costs, differences, and the sales report MUST NOT be visible to customers or to anyone without a staff sign-in.
- **FR-012**: Staff MAY record the dealer cost of a car, the amount the dealership paid for it. The dealer cost is optional in this version, is kept in the car's history when it changes, and is never shown on a sales report or any customer page.
- **FR-010**: Each sold car MUST display both its asking price at the moment of sale and the first price it was listed at, side by side (see Clarifications).
- **FR-011**: A sold car recorded before this feature has no sale price. Staff MUST enter its sale price before any other change to that car is saved. The price entry follows the same rules as FR-002 and is kept in the car's history.

### Key Entities

- **Car**: An existing vehicle. A sold car also has a sale price, a sale date, and the staff member who marked it sold. A car may also carry a dealer cost, which is internal to staff (FR-012).
- **Sale history entry**: One recorded change to a car's sale: the previous and new sale price, the reason (sold, corrected, or cleared), the staff member, and the time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A staff member can mark a car sold with its sale price in under 30 seconds.
- **SC-002**: 100% of cars marked sold after this feature ships have a sale price on record.
- **SC-003**: The difference shown for every sold car equals the sale price minus the listed price, in 100% of tested cases.
- **SC-004**: Customers never see a sale price, a difference, or the sales report on any page.
- **SC-005**: The sales report for a one-month range loads in under 3 seconds at the current scale of a few thousand cars.
- **SC-006**: Every correction to a sale price is visible in the car's history, with the staff member and time, for 100% of corrections.

## Assumptions

- The listed price for a sold car is the asking price at the moment of sale, entered in US dollars. The first listed price is shown alongside it (FR-010).
- The sale date is the date the car was marked sold. This feature does not record payment, financing, deposits, or taxes.
- The difference percentage is calculated on the listed price, rounded to one decimal place.
- Only signed-in staff can see sales information. Customers see no change to the public pages.
- Sold cars are not deleted when the sale is recorded, so the history of every sold car stays available.

## Out of Scope

- Payment, financing, invoicing, or trade-in values.
- Commission or profit calculations. The dealer cost is recorded (FR-012), but no margin or profit is computed from it.
- Customer-facing sale information.
- Sales reports by staff member or dealership (follow-up).
