# Contributing to `ledger`

Thanks for your interest in contributing — we appreciate it! This file explains how to run the app locally, test your changes, and create a useful Pull Request.

## Getting started

1. Fork and clone the repo.
2. Create a feature branch from `main`:

```bash
git checkout -b feat/short-description
```

3. Run the app and tests locally:

```bash
flutter pub get
flutter analyze
flutter test --reporter expanded
```

## Coding style

- We follow rules in `analysis_options.yaml` (flutter_lints by default).
- Run `flutter analyze` and ensure there are no new warning or error lints.
- Keep code simple, readable and testable. Avoid one-off or global state where possible.

## Tests

- Unit tests for models and services belong under `test/models/` and `test/services/`.
- Widget tests go under `test/components/` or `test/widgets/` and use `WidgetTester`.
- For service tests that rely on DB, prefer to use fakes with a `List<Map<String, dynamic>>` backing store or `sqflite_common_ffi` if you must run SQL in the VM (see `TESTING.md`).

## Pull request process

- Provide a short, descriptive PR title and summary of changes.
- Reference related issues (if any).
- Include tests for any logical/functional change.
- Keep commits focused and logically grouped. Rebase or squash as necessary.

---

If you'd like anything listed in here expanded (e.g., contribution workflow, issue templates), tell me how you want it organized and I'll add it.
