# Quickstart: Verify the Modern UI

Run these checks after each phase in [plan.md](plan.md). Expected results are in the right-hand column of each step.

## Prerequisites

- Ruby 3.4.10 (see `.ruby-version`) and the bundle installed (`bundle install`).
- Development database set up (`bin/rails db:prepare`) and seeded (`bin/rails db:seed`). Seeds create a staff user, `staff@example.test`, with the development-only password.
- Google Chrome, for system tests (Capybara with headless Chrome).

## 1. Build the stylesheet

```bash
bin/rails tailwindcss:build
```

Expected: `app/assets/builds/tailwind.css` is written and is not empty.

## 2. Run the watcher in development

In a second terminal, keep Tailwind rebuilding on save:

```bash
bin/rails tailwindcss:watch
```

Then start the app in the first terminal:

```bash
bin/dev
```

Expected: `http://localhost:3000` shows styled pages. Changing a class in a view and refreshing shows the change. Note: `bin/dev` does not start the Tailwind watcher on its own, so this second terminal is required.

## 3. Run the test suites

```bash
bin/rails test
bin/rails test:system
```

Expected: the same pass counts as the baseline recorded in [research.md](research.md#8-baseline-test-counts). No test was edited to make it pass, except where a spec-driven text change is noted in the plan.

## 4. Visual check at two widths

Use Chrome DevTools device mode, or the `run` skill if it is available.

| Width | Pages to check | Pass when |
|-------|----------------|-----------|
| 375px | `/`, `/cars/:id`, `/favorites`, `/session/new`, `/manage/cars`, `/manage/cars/new` | No horizontal scroll. Header nav wraps cleanly. All buttons and nav links are at least 44px tall. |
| 1280px | Same pages | Customer grid shows 3 or more columns. Manage table shows status badges. |

Also check a flash message: sign in with a wrong password and confirm the red alert shows an icon, not only red color.

## 5. Accessibility spot check

- Tab through the header and the car form. Every control shows a visible focus ring.
- Check the text on `bg-slate-50` and white backgrounds against WCAG AA (4.5:1 for body text).

## 6. Full CI

```bash
bin/ci
```

Expected: all steps pass (RuboCop, bundler-audit, importmap audit, Brakeman, Rails tests, seed replant, system tests).

## Known gaps

- Dark mode is out of scope (spec Assumptions).
- Mailer templates are not restyled (spec Assumptions).
