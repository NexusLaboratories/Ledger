# ledger

A personal finance Ledger app (Flutter) used for tracking accounts, transactions, categories, and tags. This repository contains a Flutter mobile/tablet/desktop app with a small, dependency-injected service layer and a SQLCipher-backed database for encrypted local storage.

---

## Table of Contents

- Overview
- Quick start
- Development setup
- Running the app
- Testing
- Architecture and structure
- Contributing
- Code style & linting
- FAQ & Troubleshooting

---

## Overview

`ledger` is a small Flutter app intended to demonstrate clean separation between UI and data layers (models and services) using a GetIt service locator, as well as secure local storage using `sqflite_sqlcipher`.

Key features
- Account management
- Transaction entry and listing
- Categories and tags
- Budgets and spending tracking
- Data import/export (JSON format)
- Encrypted local database
- Testable codebase with dependency injection

---

## Quick start

Requirements
- Flutter 3.x/4.x SDK and Dart 3.x (see `pubspec.yaml` environment)
- macOS / Windows / Linux for desktop; Android Studio or Xcode for device testing

Clone repository

```bash
git clone <your-repo-url> ledger
cd ledger
```

Get packages

```bash
flutter pub get
```

Run on an emulator or device

```bash
flutter run
```

Build for specific platforms

- Android: `flutter build apk` or `flutter build appbundle`
- iOS: `flutter build ios`
- macOS: `flutter build macos`
- Windows: `flutter build windows`
- Web: `flutter build web`

Note: iOS builds require a macOS host with Xcode installed.

---

## Development setup

1. Install Flutter (https://docs.flutter.dev/get-started/install)
2. Ensure `flutter doctor` passes and you can run device emulators.
3. Run `flutter pub get` to fetch dependencies.
4. Optionally configure a code editor like VS Code or Android Studio.

Service locator and app init behaviour is implemented in `lib/services/service_locator.dart` and `lib/services/app_init_service.dart`. The encrypted DB uses `sqflite_sqlcipher` and opens during startup if the DB password is set (via `UserPreferenceService`). See `lib/services` for details.

---

## Running tests

This repository includes unit and widget tests. To run the test suite:

```bash
flutter test --reporter expanded
```

For database-backed tests that need to run in the VM you can use `sqflite_common_ffi` (see `TESTING.md`) or run them on a device/emulator.

---

## Architecture & Structure

Top-level folders
- `lib/` — App source code
	- `lib/main.dart` — App entry point
	- `lib/services` — DI service locator and app services (DB, accounts, transactions, etc.)
	- `lib/models` — Data models used across the app
	- `lib/components` — Reusable UI widgets
	- `lib/screens` — Page-level screens and routes
	- `lib/presets` — Theme, routes and presets
	- `lib/modals` — Popups and dialogs
	- `lib/utilities` — Helpers and utils
- `test/` — Unit, service and widget tests

Design and patterns
- Service locator (GetIt) in `lib/services/service_locator.dart` configures lazily instantiated services.
- Services accept abstract DB interfaces so they are testable and can accept fakes for unit tests (see `TESTING.md`).
- Encrypted DB: `sqflite_sqlcipher` is used for secure local storage; `DatabaseService` manages DB init/open/close.

---

## Contributing

We welcome contributions — see `CONTRIBUTING.md` for details on coding style, PR process, testing, and running the project locally.

---

## Code style & linting

This project uses `analysis_options.yaml` and `flutter_lints` for consistent linting. Please run `flutter analyze` and `flutter test` before submitting PRs.

---

## FAQ & Troubleshooting

- `flutter doctor` shows an error about Xcode/Android SDK: make sure you meet the platform development requirements from Flutter's install documentation.
- Database password missing: If your device does not have a DB password, the app initializes a fresh DB and continues without opening an encrypted DB. Set a password using `UserPreferenceService` to test encrypted DB behavior.

---

See additional documentation in `docs/ARCHITECTURE.md` and `docs/DEVELOPMENT.md` for architecture details and development steps. If you want CI examples (GitHub Actions) or onboarding checklists, I can add `docs/CI.md` or `docs/ONBOARDING.md`.

---

