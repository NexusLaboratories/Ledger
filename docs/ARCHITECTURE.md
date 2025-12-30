# Architecture and Design

This document explains the project's high-level architecture, important modules, and patterns used in the app.

## High-level design

- App entry point: `lib/main.dart` — configures services (GetIt), initializes DB and user preferences, and starts the MaterialApp.
- UI: The app uses widget components and screens in `lib/components` and `lib/screens`.
- Services: Application business logic and DB-related operations are in `lib/services`.
- Models: Data classes under `lib/models` encapsulate domain objects (transactions, accounts, tags, categories, items).
- Presets: Routing and theming are in `lib/presets`.

## Dependency injection

- We use GetIt (`lib/services/service_locator.dart`) for a tiny dependency injection system.
- Services are registered using `registerLazySingleton` — this keeps runtime performance steady while enabling easy test injection.

## Database and storage

- `sqflite_sqlcipher` is used for an encrypted SQLite DB.
- `DatabaseService` (in `lib/services/database`) encapsulates DB lifecycle and table setup.
- Services accept abstract DB service interfaces to facilitate testing with in-memory fakes.

## Testing strategy

- Unit tests for models and services (no platform dependencies) should be kept small and deterministic.
- Widget tests use `WidgetTester` and should avoid real DB access by injecting fakes.
- Where necessary, `sqflite_common_ffi` can be used to run DB code in the Dart VM (see `TESTING.md`).

## Error handling and logging

- Keep domain errors close to where they occur. Prefer returning `Result` objects or throwing controlled exceptions that are handled by services.
- Use a shared logging approach in `lib/utilities` for consistent logging output where necessary.

## Extensibility

- The GetIt configuration can be extended with additional services by adding to `lib/services/service_locator.dart`.
- New UI components should follow the existing layout patterns and be small and testable.

If you'd like, I can add class diagrams, sequences for typical flows, or a collaborator onboarding checklist.
