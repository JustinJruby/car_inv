# Quickstart: Car Popularity by Favorites

Validation guide for feature 006. Run after each phase in plan.md.

## Prerequisites

- Development database set up (`bin/rails db:prepare db:seed`).
- Migration applied (`bin/rails db:migrate`).
- Google Chrome, for the system test.

## 1. Model rules

```bash
bin/rails test test/models/favorite_test.rb
```

Expected: all pass. The tests cover one active favorite per visitor per car, removal, re-saving as a new row, the all-time and 30-day counts, and the rule that removed favorites do not count.

## 2. Saving and removing on the server

```bash
bin/rails test test/controllers/favorites_controller_test.rb
```

Expected: saving a car creates an active favorite for the visitor's cookie, removing it sets `removed_at`, and the favorites page lists only active favorites.

## 3. Staff ranking

```bash
bin/rails test test/controllers/manage/popularity_controller_test.rb
```

Expected: cars appear most favorited first, ties are ordered by make and model, the 30-day window excludes older favorites, and an empty ranking shows "No favorites yet".

## 4. Privacy

```bash
bin/rails test test/controllers/favorite_privacy_test.rb
```

Expected: the stored favorite has no personal detail, the visitor cookie is httponly, and no customer page shows a count or ranking.

## 5. Browser walk-through (development server)

1. Open a car page, click "Save to favorites", reload the page, and open `/favorites`. Expected: the car is listed.
2. Remove it. Expected: it leaves `/favorites`.
3. Sign in as staff and open `/manage/popularity`. Expected: cars ordered by active favorites, with the window choice working.

## 6. Full check

```bash
bin/ci
```

Expected: every step passes.
