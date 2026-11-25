# Research: Car Inventory

Each decision records what was chosen, why, and what else was considered. No open `NEEDS CLARIFICATION` items remain.

## 1. Staff sign-in

- **Decision**: Use the built-in `bin/rails generate authentication` (User, Session, `has_secure_password`) and uncomment `bcrypt`.
- **Rationale**: Rails 8 generates this with sessions stored in the database. It needs no extra gem and shows a current built-in pattern.
- **Alternatives considered**: Devise (heavier, with a larger API to learn); a hand-written login (more code to secure).

## 2. Throttling failed sign-ins (FR-002)

- **Decision**: `rate_limit to: 10, within: 3.minutes, only: :create` on the sessions controller, with `by:` set to the submitted email (lowercased), so the limit applies per email address.
- **Rationale**: Rails' `rate_limit` supports a custom `by:` lambda (the default is the client IP). Keying by email matches FR-002. The error response is the same whether the email exists or not, which meets the "do not reveal" requirement.
- **Alternatives considered**: Keying by IP only (doesn't match FR-002). Rack::Attack (adds a gem the built-in feature makes unnecessary).

## 3. VIN uniqueness among "active" listings (FR-006)

- **Decision**: Enforce uniqueness with a partial unique index on `vin` where `status` is not sold, plus a model validation with the same scope. Store VINs uppercase with `normalizes`.
- **Rationale**: The spec says "active listings" without defining it. Treating sold cars as inactive lets a car that was sold and later returns to inventory be re-listed. A partial index is supported by SQLite and enforces it at the database level.
- **Alternatives considered**: Unique across all statuses (blocks re-listing a sold car). A model validation only (can race under concurrent saves).
- **Assumption recorded**: "Active" means status available or reserved. Flagged for confirmation at review.

## 4. VIN format

- **Decision**: Require exactly 17 letters or digits (FR-006). Do not exclude I, O, or Q.
- **Rationale**: The spec sets only a length rule. Excluding I, O, and Q would reject inputs the spec allows.
- **Alternatives considered**: Full ISO 3779 check digit validation (stricter than the spec, adds rules nobody asked for).

## 5. Photos

- **Decision**: `has_many_attached :photos` on Car, with gallery variants via `image_processing` (already in the Gemfile). Accept JPEG, PNG, and WebP only, with a per-file size cap set in the model.
- **Rationale**: Active Storage is Rails' built-in file system, and variants give thumbnails for the gallery.
- **Alternatives considered**: Storing images in an external service (adds infrastructure the spec doesn't require).

## 6. Rich-text descriptions (FR-008)

- **Decision**: `has_rich_text :description` using Action Text with the default Trix editor.
- **Rationale**: Built in, and it sanitizes HTML by default.
- **Alternatives considered**: Markdown in a text column (less formatting control, and needs a renderer).

## 7. Live updates (FR-010)

- **Decision**: `broadcasts_to` on Car and feature-tag changes, with `turbo_stream_from` on the staff car page and inventory list. Solid Cable carries the broadcasts.
- **Rationale**: Turbo Streams broadcast changes over WebSockets with no custom JavaScript. Solid Cable keeps it on the database, with no Redis.
- **Alternatives considered**: Polling every few seconds (more load, and slower than the 5-second target at scale). Redis-backed Action Cable (extra service).

## 8. Conflicting edits (FR-021)

- **Decision**: Add a `lock_version` integer column to Car for optimistic locking. The controller rescues `ActiveRecord::StaleObjectError` and asks the staff member to reload.
- **Rationale**: Built in, and it prevents silent overwrites without holding database locks.
- **Alternatives considered**: Pessimistic locking (blocks other staff while editing). Last-write-wins (loses edits, which the spec rules out).

## 9. Customer favorites without an account (FR-014, FR-015)

- **Decision**: Store favorites in `localStorage` through a Stimulus controller. The favorites page loads car data from the server by ID (`/favorites?ids=1,2,3`).
- **Rationale**: The spec says favorites live in the browser, and `localStorage` persists across reloads. Stimulus is already in the app.
- **Alternatives considered**: Cookies (sent with every request, and limited in size). A server-side favorites table (requires customer identity, which the spec rules out).

## 10. Price-drop badge (FR-016, Clarification 1 option B)

- **Decision**: Set `price_dropped_at` on Car when a staff member saves a lower asking price. Each favorite in `localStorage` records when the customer last opened favorites. The badge shows when `price_dropped_at` is later than that time.
- **Rationale**: Option B asks for no email, so the signal must live on the car and be compared in the browser.
- **Alternatives considered**: Sending an email (ruled out by the clarification). A "price history" table (more than the spec needs).

## 11. Nightly stale-listing report (FR-017)

- **Decision**: A recurring job in `config/recurring.yml` (Solid Queue) runs nightly. It selects cars where `updated_at` is older than 60 days and sends one email per staff member with `deliver_later`. Feature tag changes and photo changes touch the car, so they count as edits.
- **Rationale**: Uses built-in scheduling. `touch: true` on the join and photo attachment callbacks makes `updated_at` reflect every edit the spec counts.
- **Alternatives considered**: Cron outside the app (adds an operational component). Using `status` changes only (misses photo and description edits, which the spec counts).

## 12. Share links (FR-018, FR-019)

- **Decision**: `generates_token_for :share, expires_in: 7.days` on Car. The share page renders only public fields.
- **Rationale**: Expiry is built into the token, so no table or cleanup job is needed. Rails signs the token.
- **Alternatives considered**: A share-links table with a cleanup job (more to build and maintain).

## 13. Customer browse and caching (FR-011 to FR-013, SC-004)

- **Decision**: Scopes for filters, combined in the controller. Fragment caching with `cache car` for car cards, backed by Solid Cache.
- **Rationale**: Scopes are composable and easy to test. Cache keys include `updated_at`, so the cache clears when a car changes.
- **Alternatives considered**: A search engine service (unnecessary at this scale).

## 14. Parameter handling

- **Decision**: `params.expect` for every create and update action.
- **Rationale**: It is Rails 8's strict replacement for `params.require(...).permit(...)`, and it rejects malformed input early.
- **Alternatives considered**: `params.require.permit` (still works, but it is the older pattern).

## 15. Testing approach

- **Decision**: Minitest with fixtures. Request tests cover the private-contact rule (FR-020) and the share page (FR-019). System tests cover live updates and favorites with a headless browser.
- **Rationale**: Built-in, and `bin/ci` runs it all before merge.
- **Alternatives considered**: RSpec (a different style, and not needed for this app).
