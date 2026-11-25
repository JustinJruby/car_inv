# Quickstart: Car Inventory Validation

This guide runs the feature end to end. Use it to confirm each user story works after implementation. It does not repeat implementation details; see `plan.md` for the design and `data-model.md` for fields.

## Prerequisites

- Ruby 3.4.10 and Rails 8.1.4.1 (as installed for this app)
- Dependencies installed with `bundle install`
- The database prepared (`bin/rails db:prepare`)
- A staff account created with the console or seed data (staff accounts are created by an administrator, per the spec)

## Setup

```bash
cd ~/projects/alpha
bundle install
bin/rails db:prepare
bin/rails server
```

Open `http://localhost:3000`. Keep the server running for every step below.

## Scenario 1: Staff sign-in and throttling (US1, FR-001, FR-002)

1. Go to the staff sign-in page and sign in with a valid staff account. **Expect**: you reach the staff inventory.
2. Sign out. Enter a wrong password for a staff email 10 times within 3 minutes. **Expect**: after the limit, the page says to try again later, and the message is the same whether the email exists or not.
3. Enter a wrong password for an email that doesn't exist, 10 times. **Expect**: the same throttled response.

## Scenario 2: Manage a car listing (US1, FR-003 to FR-006)

1. As staff, create a car with make, model, year, VIN, mileage, asking price, and status. **Expect**: the car appears in the inventory.
2. Enter a VIN with 16 characters. **Expect**: the car is not saved, and the message names the VIN field.
3. Enter the same VIN as an existing available car. **Expect**: rejected as a duplicate.
4. Change the car's asking price. **Expect**: the new price shows in the inventory and on the car page.
5. Remove the car. **Expect**: it's gone from the inventory and from customer search.

## Scenario 3: Photos, description, features (US4, FR-007 to FR-009)

1. Attach three photos to a car. **Expect**: the car page shows a gallery in the order added.
2. Write a description with bold text and a bulleted list. **Expect**: the customer view shows the formatting.
3. Tag the car "leather seats" and "AWD". **Expect**: a customer filtering by "AWD" finds it.

## Scenario 4: Live updates across screens (US3, FR-010, FR-021)

1. Open the same car on two staff browser windows.
2. In window A, mark the car reserved. **Expect**: window B shows "reserved" within 5 seconds, with no reload.
3. In window A, load the edit form, then in window B change the price and save. Save the form in window A. **Expect**: window A is told to reload, and window B's price is not overwritten.

## Scenario 5: Customer search and filters (US2, FR-011 to FR-013)

With at least two makes, a range of prices and years, and one car tagged AWD:

1. Filter by one make. **Expect**: only that make appears.
2. Set a minimum and maximum price. **Expect**: only cars in range appear.
3. Filter by AWD. **Expect**: only AWD cars appear.
4. Mark one car reserved and one sold. Browse as a customer. **Expect**: neither appears.
5. Apply a filter with no matches. **Expect**: "no cars match" appears.

## Scenario 6: Favorites without an account (US5, FR-014, FR-015)

1. As a customer (not signed in), save two cars as favorites. **Expect**: both appear in favorites.
2. Reload the page. **Expect**: both are still listed.
3. Clear browser storage. **Expect**: favorites are gone.
4. Mark a favorited car sold. **Expect**: it shows as unavailable in favorites.

## Scenario 7: Price drop badge (US6, FR-016)

1. As a customer, save a car as a favorite.
2. As staff, lower that car's asking price.
3. As the same customer, reopen favorites on the same browser. **Expect**: the car shows a "Price dropped" badge.
4. Reopen favorites again. **Expect**: the badge is gone until the next reduction.
5. Confirm no email was sent to anyone for this change (check the mailer log).

## Scenario 8: Nightly stale-listing report (US7, FR-017)

1. Create one car, then set its `updated_at` to 61 days ago. Create another and leave it recent.
2. Run the recurring job once by hand. **Expect**: staff receive a report that lists only the 61-day-old car.
3. Edit a photo on the old car, then run again. **Expect**: the car no longer appears in the report.

## Scenario 9: Share link (US8, FR-018, FR-019)

1. As staff, create a share link for a car. **Expect**: anyone with the link can view the car.
2. Open the link without signing in. **Expect**: the page shows photos, description, and features, and no contact details.
3. Open the link after 7 days (simulate by advancing time in the test environment). **Expect**: a "link expired" message and no car details.

## Scenario 10: Private contact details (FR-020)

1. As a customer, open a car's public page and the share page. **Expect**: no contact name, phone, or email appears.
2. As staff, open the same car. **Expect**: contact details appear.

## Automated checks

Run the full suite before merging:

```bash
bin/rails test
bin/rails test:system
bin/ci
```

**Expect**: all pass. Request tests cover Scenario 10 and the share page; system tests cover Scenarios 4 and 6.
