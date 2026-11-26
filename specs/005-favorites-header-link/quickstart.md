# Quickstart: Favorites Header Link

Validation guide for feature 005.

## Prerequisites

- Development database set up (`bin/rails db:prepare db:seed`).
- Google Chrome, for the system test.

## 1. Layout tests (signed-out and signed-in)

```bash
bin/rails test test/controllers/ui_layout_test.rb
```

Expected: all pass. The tests check that the header shows a "Favorites" link next to "Inventory" for both visitor states.

## 2. Click test (browser)

```bash
bin/rails test:system test/system/favorites_header_test.rb
```

Expected: a visitor on the home page clicks "Favorites" in the header and lands on the favorites page.

## 3. Manual check at phone width

1. Start the app (`bin/dev`) and open the home page in Chrome's device mode at 375px.
2. Confirm "Favorites" wraps with the other header links and each link is at least 44px tall.
3. Click "Favorites" and confirm it opens the favorites page.

## 4. Full check

```bash
bin/ci
```

Expected: every step passes.
