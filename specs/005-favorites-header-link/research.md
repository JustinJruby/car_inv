# Research: Favorites Header Link

## R1. Placement and label

**Decision**: Put "Favorites" in the header navigation directly after "Inventory", for every visitor. Label it "Favorites".

**Rationale**: The spec asks for placement next to "Inventory" (FR-003) and visibility for all visitors (FR-001). "Favorites" matches the existing "Save to favorites" button, so visitors see the same word in both places.

**Alternatives considered**:
- Show the link only to signed-in visitors. Rejected: favorites are stored in the browser and work without an account (spec 001, US5), so signed-out visitors need the link most.
- Label it "Saved cars", matching the favorites page heading. Rejected: the page heading is less visible than the button wording, and "Favorites" is the term the rest of the site uses.

## R2. Keeping the tap target

**Decision**: Reuse the header's existing link classes, which include `min-h-11`.

**Rationale**: Feature 002 set the 44px minimum on header links (US3-3). Copying those classes keeps the new link consistent without new CSS.

## R3. Testing the link

**Decision**: Add the link checks to the existing `test/controllers/ui_layout_test.rb`, and add one system test that clicks the link from the home page.

**Rationale**: The layout test already checks the header links for both visitor states, so the new checks belong there. A system test confirms the click works in a real browser.
