# Research: Car Popularity by Favorites

## R1. How favorites are stored on the server

**Decision**: One row per save of a car by a visitor, in a `favorites` table, with `saved_at` and `removed_at`. A removal sets `removed_at`. A save after a removal creates a new row.

**Rationale**: The 30-day window (spec FR-006) needs the time each favorite was saved. A row per save keeps that history without storing identity beyond the visitor identifier. The count is a query over active rows, so it cannot drift from the stored favorites.

**Alternatives considered**:
- A counter per car, incremented and decremented. Rejected: it cannot answer the 30-day window, and it can drift from the actual favorites if a request fails halfway.
- Re-activating an old row on a new save. Rejected: it loses the time of the new save, so the 30-day window would be wrong.

## R2. Visitor identifier

**Decision**: A random UUID created on first visit or save, kept in a permanent cookie that is httponly and signed. It is the only identifier stored with a favorite. It is never shown on any page.

**Rationale**: FR-002 forbids names, emails, and other personal details, and a random identifier is the least that lets the server keep a visitor's favorites together. Signing the cookie stops a visitor from changing it to read another visitor's favorites.

**Alternatives considered**:
- Sign in each visitor. Rejected: spec 001 keeps customer accounts out of scope.
- Store the identifier in browser storage instead of a cookie. Rejected: the server cannot read browser storage on a request, so the cookie is the only way it reaches the server.

## R3. Browser changes

**Decision**: The favorite button calls the server to save or remove the favorite. The favorites page reads the visitor's favorites from the server. Browser storage keeps only the last-seen time for each saved car, for the price-drop badge.

**Rationale**: Counting requires the server to know each favorite. The price-drop badge is about what the visitor has seen on this device, so it stays in the browser.

**Alternatives considered**: Keep favorites in browser storage and sync them to the server. Rejected: two sources of truth, and more code than saving directly.

## R4. Counting and ranking

**Decision**: A car's count is the number of its active favorites (`removed_at` empty). The ranking query groups active favorites by car, optionally limited to `saved_at` within the last 30 days. Ties are ordered by make, then model (FR-005).

**Rationale**: One query for both windows, and a stable tie order for the spec's requirement.

## R5. Time window choice

**Decision**: The ranking page has a choice, all time or last 30 days, passed as a query parameter. The default is all time.

**Rationale**: Q3 = C: staff choose the window. All time is the default because it is the simpler view.

## R6. Privacy and customer pages

**Decision**: Favorite counts and the ranking appear only on staff pages. The customer pages do not change. A privacy test checks the stored columns for personal detail and the cookie flags.

**Rationale**: Q2 = A: staff only. The test is the guard against a future change leaking the count.

## R7. Favorites saved before this change

**Decision**: Not migrated. Favorites saved in a browser before this change stay in that browser's storage and are not moved to the server. The favorites page shows only server favorites after the change.

**Rationale**: The server has no link to a browser's old favorites, and nothing identifies them. Moving them would need the old browser to run the migration, which adds code for a small amount of data. The user should confirm this is acceptable.

**Alternatives considered**: A one-time migration when the favorites page loads with old browser favorites. Rejected for now: it adds a path that runs once per browser, and the user should decide whether the existing favorites are worth carrying over.

## Implementation notes (006)

**Baseline (T001)**: before any change, `bin/rails test` ran 148 tests (526 assertions) and `bin/rails test:system` ran 10 tests, all passing.

**Final**: `bin/rails test` 171 runs, 622 assertions, 0 failures. `bin/rails test:system` 10 runs, 48 assertions, 0 failures. `bin/ci` passes all steps.

**Known risk**: the system suite stalled three times during development, after the browser started and the first test passed. Four clean runs followed, and each stall happened only in the full system suite (the favorites browser tests passed when run alone). The cause was not determined.
