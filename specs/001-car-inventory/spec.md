# Feature Specification: Car Inventory

**Feature Branch**: `001-car-inventory`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "A car inventory app for a small dealership group. Staff sign in to manage their cars, and customers browse the available inventory."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Staff manage car listings (Priority: P1)

A signed-in staff member adds a new car to the inventory with its details, edits it later when the price or status changes, and removes it when it's no longer listed.

**Why this priority**: Without listings there is no inventory. This is the core purpose of the app.

**Independent Test**: Sign in as staff, create a car with all required details, edit its price, then remove it. Each step is visible in the inventory.

**Acceptance Scenarios**:

1. **Given** a signed-in staff member, **When** they submit a new car with make, model, year, VIN, mileage, asking price, and status, **Then** the car appears in the inventory.
2. **Given** a car in the inventory, **When** a staff member changes its asking price, **Then** the new price is shown everywhere the car appears.
3. **Given** a car in the inventory, **When** a staff member removes it, **Then** it no longer appears in the inventory or in customer search results.
4. **Given** a new car form, **When** a required field is missing or the VIN is not 17 characters, **Then** the car is not saved and the staff member is told which field needs correction.

---

### User Story 2 - Customers search and filter available cars (Priority: P1)

A customer, without signing in, searches the inventory and narrows results by make, price range, year, and features.

**Why this priority**: Customers are the buyers the inventory exists to serve. Browsing is the main way they find a car.

**Independent Test**: Load the public inventory with a known set of cars and apply each filter. Only matching available cars appear.

**Acceptance Scenarios**:

1. **Given** cars of several makes in the inventory, **When** a customer filters by one make, **Then** only cars of that make appear.
2. **Given** cars at several prices, **When** a customer sets a minimum and maximum price, **Then** only cars within that range appear.
3. **Given** cars with different features, **When** a customer selects "AWD", **Then** only cars tagged AWD appear.
4. **Given** cars with status reserved or sold, **When** a customer browses or searches, **Then** those cars do not appear in results.
5. **Given** a filter that matches no cars, **When** the customer applies it, **Then** a clear "no cars match" message is shown.

---

### User Story 3 - Staff see status and price changes live (Priority: P2)

When one staff member changes a car's status or price, other staff members who have that car open see the change without reloading their page.

**Why this priority**: Two staff members must not sell or quote the same car. Stale status causes lost sales.

**Independent Test**: Open the same car on two staff screens, change its status on one, and confirm the other updates with no reload.

**Acceptance Scenarios**:

1. **Given** two staff members viewing the same car, **When** one marks it reserved, **Then** the other sees "reserved" within 5 seconds without reloading.
2. **Given** a staff member viewing the inventory list, **When** another staff member changes a car's price, **Then** the list shows the new price within 5 seconds.

---

### User Story 4 - Photos, descriptions, and features (Priority: P2)

Staff attach photos to a car and write a rich-text description and feature tags. Customers see all of it on the car's page.

**Why this priority**: Photos and descriptions decide whether a customer contacts the dealership about a car.

**Independent Test**: Attach three photos and a formatted description to a car, then view it as a customer.

**Acceptance Scenarios**:

1. **Given** a car, **When** a staff member attaches photos, **Then** the car page shows them in a gallery in the order they were added.
2. **Given** a car, **When** a staff member writes a description with bold text and a list, **Then** the customer view shows that formatting.
3. **Given** a car, **When** a staff member adds the feature tags "leather seats" and "AWD", **Then** a customer filtering by either tag finds that car.

---

### User Story 5 - Customers save favorites without an account (Priority: P2)

A customer saves a car as a favorite. Favorites persist in their browser and appear in a favorites list on the same device.

**Why this priority**: Lets interested customers come back to a car without requiring sign-up.

**Independent Test**: Save two cars as favorites, reload the page, and confirm both still appear. Clear browser storage and confirm they are gone.

**Acceptance Scenarios**:

1. **Given** a customer viewing a car, **When** they tap "Save", **Then** the car appears in their favorites list.
2. **Given** saved favorites, **When** the customer reloads the page, **Then** the favorites are still listed.
3. **Given** a car that is later marked sold, **When** the customer views favorites, **Then** the car is shown as no longer available.

---

### User Story 6 - Price reduction badge on favorites (Priority: P3)

When a staff member marks a price reduction on a car, any customer who saved that car as a favorite sees a "Price dropped" badge the next time they open favorites on the same device. No email is sent.

**Why this priority**: Brings interested customers back without collecting personal contact details. See Clarification 1.

**Independent Test**: Save a car as a favorite, mark a price reduction as staff, then reopen favorites on the same device and confirm the badge appears.

**Acceptance Scenarios**:

1. **Given** a car with saved favorites, **When** a staff member marks a price reduction, **Then** each customer who saved that car sees a "Price dropped" badge the next time they open favorites on that device.
2. **Given** a car with no favorites, **When** a price reduction is marked, **Then** nothing else is affected and no messages are sent.
3. **Given** a customer who has already seen the badge, **When** they reopen favorites, **Then** the badge is not shown again until the next price reduction.

---

### User Story 7 - Stale-listing report (Priority: P3)

Each night, staff receive a report of listings that have not been edited in 60 days.

**Why this priority**: Helps keep the inventory current, but staff can work without it.

**Independent Test**: Create a car with a last-edited date 61 days ago and one edited yesterday. Run the nightly report and confirm only the first appears.

**Acceptance Scenarios**:

1. **Given** listings last changed more than 60 days ago, **When** the nightly report runs, **Then** those listings appear in the report.
2. **Given** listings changed within 60 days, **When** the report runs, **Then** they do not appear.

---

### User Story 8 - Share a single car via expiring link (Priority: P3)

A staff member generates a link to one car that anyone can open for 7 days. After 7 days the link stops working.

**Why this priority**: Lets staff send a car to a buyer without giving them inventory access.

**Independent Test**: Generate a link, open it successfully, then confirm it no longer works after 7 days.

**Acceptance Scenarios**:

1. **Given** a car, **When** a staff member generates a share link, **Then** anyone with the link can view that car.
2. **Given** a share link older than 7 days, **When** someone opens it, **Then** they see a "link expired" message and no car details.
3. **Given** a share link, **When** it is opened, **Then** the staff contact details for the car are not shown.

---

### Edge Cases

- A car is reserved by one staff member while another is editing its price: the price edit must still save, and the status must not revert.
- Two staff members save conflicting edits to the same car at the same time: the second save must be rejected with a message to reload, not silently overwrite.
- A VIN already used by an active listing is entered again: the system must reject the duplicate.
- A photo upload fails partway: the car must keep its previously attached photos.
- Too many failed sign-in attempts from one account: sign-in is blocked for a short period, and the message does not reveal whether the email exists.
- A customer's saved favorite is for a car that has been removed: the favorite shows the car as unavailable and does not error.
- A price reduction is marked for a car that has no photos or description: the "Price dropped" badge still appears on favorites.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Staff MUST sign in with an email address and password before they can manage listings.
- **FR-002**: The system MUST throttle sign-in attempts after repeated failures for the same email address, and MUST NOT reveal whether an email address is registered.
- **FR-003**: Staff MUST be able to create, edit, and remove car listings.
- **FR-004**: Each car MUST have a make, model, year, VIN, mileage, asking price, and status.
- **FR-005**: The status of each car MUST be one of: available, reserved, or sold.
- **FR-006**: The VIN MUST be exactly 17 characters and MUST be unique among active listings.
- **FR-007**: Staff MUST be able to attach one or more photos to a car and see them in a gallery.
- **FR-008**: Staff MUST be able to write a rich-text description for each car, including basic formatting such as bold text and lists.
- **FR-009**: Staff MUST be able to tag each car with any number of features.
- **FR-010**: When a staff member changes a car's status or price, every other staff member viewing that car or the inventory list MUST see the change within 5 seconds without reloading the page.
- **FR-011**: Customers MUST be able to browse and search the inventory without signing in.
- **FR-012**: Customers MUST be able to filter available cars by make, price range, year, and feature tag, and combine filters.
- **FR-013**: Cars with a status of reserved or sold MUST NOT appear in customer search results.
- **FR-014**: Customers MUST be able to save a car as a favorite without creating an account.
- **FR-015**: Favorites MUST persist on the customer's device across page reloads.
- **FR-016**: Staff MUST be able to mark a price reduction on a car. The system MUST show a "Price dropped" badge to each customer who saved that car as a favorite, the next time that customer opens favorites on the same device. The system MUST NOT send email for price reductions.
- **FR-017**: Each night, the system MUST produce a report of listings that have not been edited in 60 days, and deliver it to staff.
- **FR-018**: Staff MUST be able to generate a share link for a single car. The link MUST stop working 7 days after it is created.
- **FR-019**: Share links MUST NOT display staff contact details.
- **FR-020**: Staff contact details for each listing MUST be visible only to signed-in staff.
- **FR-021**: When two staff members save conflicting edits to the same car, the second save MUST be rejected and the staff member told to reload.

### Key Entities

- **Car**: A vehicle for sale. Attributes: make, model, year, VIN, mileage, asking price, status (available, reserved, sold), description, photos, feature tags, staff contact details, last-edited date.
- **Feature Tag**: A named attribute such as "AWD" or "leather seats". A car can have many; a tag can apply to many cars.
- **Staff Member**: A signed-in user who manages listings. Has an email address and password.
- **Favorite**: A customer's saved car, stored on their device. Refers to one car.
- **Share Link**: A time-limited link to one car. Has a creation date and an expiry date 7 days later.
- **Price Drop Marker**: A record on a car that a price reduction was marked, and the time it was marked. Customers see it as a badge on their favorites when they next open them.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A staff member can list a new car with at least three photos in under 5 minutes.
- **SC-002**: A status or price change made by one staff member is visible to other open staff screens within 5 seconds, without reloading.
- **SC-003**: A customer sees a car's status change on the public inventory within 5 seconds of the change being saved.
- **SC-004**: A customer can apply all four filters and see matching results in under 2 seconds.
- **SC-005**: 100% of sign-in attempts after the throttle limit are blocked for the throttle period.
- **SC-006**: 100% of share links are rejected after 7 days.
- **SC-007**: A saved favorite remains available after a page reload with no sign-up.

## Clarifications

### Session 2026-11-25

- Q: How should price-reduction notifications reach customers who saved a car as a favorite, when favorites are stored only in the browser and have no email address? → A: Option B. No email. Favorites show a "Price dropped" badge the next time the customer opens favorites on the same device.

## Assumptions

- Staff accounts are created by an administrator. Self-service sign-up for staff is out of scope.
- Customers are anonymous visitors. Customer accounts, login, and order history are out of scope.
- The inventory is for a small number of dealerships (under 10 locations). Each car belongs to one location.
- Staff contact details are a phone number and an email address stored per car.
- "Unchanged for 60 days" means no edit to the car's record, including price, status, photos, description, or features.
- A share link opens a read-only public page for one car, with the car's photos, description, and features. It does not show inventory search or staff details.
- Mobile browsers are supported, but a native mobile app is out of scope.
- Photos are limited to common image formats (JPEG, PNG, WebP) at a reasonable maximum size per file.
- The nightly report is sent to all staff members with an email address on file.
- Email is used only for staff sign-in, the nightly report, and the staff contact details on each car. Customers are never asked for an email address.
