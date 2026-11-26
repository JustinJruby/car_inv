# Alpha Constitution

## Core Principles

### I. Spec Before Code
Every feature MUST start from a written specification in `specs/<feature>/` before implementation begins.
Each spec MUST state the problem, the expected behavior, and how success is checked.
Rationale: a written spec makes scope and acceptance criteria reviewable before effort is spent.

### II. Test-Backed Changes
Every behavior change MUST include tests that fail without the change and pass with it.
Rationale: tests are the only durable proof that a feature still works after later edits.

### III. Simplicity First
The simplest design that meets the spec MUST be chosen.
Abstractions, dependencies, and configuration MUST be justified by a current requirement, not a
possible future one.
Rationale: unused complexity is a recurring cost to every future change.

### IV. Small, Reviewable Changes
Each change SHOULD address one spec or one task.
A change that cannot be reviewed in a single sitting SHOULD be split.
Rationale: small changes are easier to verify and easier to roll back.

### V. Decisions Are Recorded
Choices that are hard to reverse (stack, data formats, public interfaces) MUST be recorded with
their reasons in the relevant spec or plan.
Rationale: future contributors need the why, not only the what.

## Development Workflow

- Work follows the Spec Kit sequence: specify, plan, tasks, implement.
- Main branch changes MUST go through a pull request.
- At least one independent review is REQUIRED. Where the repository has a single maintainer, that maintainer MAY merge their own pull request without an independent review, provided the pull request records that no independent review took place.
- Commit messages SHOULD describe the why in the subject line.

## Quality Gates

- Tests MUST pass before a change is merged.
- A change that alters public behavior MUST update the affected spec and documentation in the same change.

## Governance

This constitution supersedes other practices in this project where they conflict.
Amendments MUST be proposed as a change to this file, with the reason stated in the commit message.
Versioning follows semantic rules: MAJOR for removed or redefined principles, MINOR for new principles
or materially expanded guidance, PATCH for clarifications and wording fixes.
Compliance is checked during pull request review; reviewers MUST flag changes that violate a principle.

**Version**: 1.1.0 | **Ratified**: 2026-11-25 | **Last Amended**: 2026-11-26
