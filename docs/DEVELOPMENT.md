# Development Guide

This document provides step-by-step setup notes and common development tasks for contributors.

## Prerequisites

- Flutter SDK (stable, check `pubspec.yaml` for Dart environment version)
- Android SDK + Android Studio (for Android builds and emulators)
- Xcode (for iOS builds on macOS)
- Optional: VS Code or Android Studio plugins for Flutter and Dart

## Setup

1. Install Flutter and verify:

```bash
flutter doctor
```

2. Pull dependencies:

```bash
flutter pub get
```

3. Setup environment variables for the DB or secrets if you use CI or local developer secrets. For encrypted DB flows, use `UserPreferenceService` to set and retrieve passwords.

## Run the app

Run on all emulators and platforms:

```bash
flutter run
```

To run a specific platform:

- Android:

```bash
flutter run -d emulator-5554
```

- iOS (on macOS):

```bash
flutter run -d <ios-device-id>
```

- macOS:

```bash
flutter run -d macos
```

- Windows:

```bash
flutter run -d windows
```

## Flutter tooling

- Run the analyzer:

```bash
flutter analyze
```

- Run formatting:

```bash
flutter format .
```

- Run tests:

```bash
flutter test
```

## Adding a new service

1. Create a new service class in `lib/services/`.
2. If the service interacts with a DB, prefer accepting an abstract DB service interface in the constructor for testability.
3. Add tests under `test/services/` and provide a small fake DB service for unit tests.
4. Register the service in `lib/services/service_locator.dart` with `getIt.registerLazySingleton<MyService>(() => MyService())`.

## Versioning

- App version is defined in `pubspec.yaml` under `version: x.y.z+build`.
- Use `flutter build` with `--build-name` and `--build-number` to override during CI if required.

## CI recommendations (optional)

- Use GitHub Actions or other CI to run `flutter analyze` and `flutter test`.
- For sensitive flows (DB password checks or integration tests), use matrix job or CI-hosted devices to validate.

---

If you want a CI pipeline example (GitHub Actions YAML), I can add a curated sample with caching, test and analyze stages. 

## Settings and user preferences

The app now supports a few user preferences persisted using `UserPreferenceService` and `SecureStorage`:

- `match_theme`: boolean — when true, the app follows system theme; otherwise `dark_mode` controls theme.
- `dark_mode`: boolean — when `match_theme` is false, this controls whether the app is dark or light.
- `notifications_enabled`: boolean — if true, notifications are enabled (UI toggle only; requires additional integration to use device notifications).
- `use_biometric`: boolean — if true, UI shows preference to enable biometric unlocking (actual biometric unlock is not wired in by default).
- `default_currency`: string — default currency code (e.g., `USD`, `EUR`, `GBP`, `INR`).

Accounts
--------

- Each account now stores a `currency` (required) as part of its model and database row.
- When creating a new account, the account form will default to the app-wide `default_currency` setting but the user must confirm/select a currency before submitting.
- Accounts can be edited later, including changing the currency from the Accounts screen.

Dependency Injection & Tests
---------------------------

- Screens and modals that operate on accounts now accept an `AbstractAccountService` via constructor so tests can inject mocks and the UI follows proper abstraction boundaries.
- For example: `AccountsScreen(accountService: myMockService)` and `AccountFormModal(accountService: myMockService)`.
	- If not provided, the screens will fall back to the app's singleton `AccountService()`.
	- This mirrors the database and service abstraction used previously to make code testable and decoupled.


These are exposed on the Settings screen (`/settings`) and persist between runs using `flutter_secure_storage`.

Budgets
-------

- A `Budget` model and service were added to manage spending budgets. Budgets are stored in the `budgets` table and can be created, updated, and deleted with `BudgetService`.
- The app includes a `BudgetsScreen`, `BudgetFormModal`, and `BudgetCard` component. They can be navigated via the drawer (`Budgets`).
- Budget progress is calculated from expense transactions within the budget period. Tests under `test/services/budget_service_test.dart` cover calculation logic.