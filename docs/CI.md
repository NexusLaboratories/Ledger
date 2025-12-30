# CI (GitHub Actions) sample

This document includes a minimal GitHub Actions sample to run lints, tests, and build checks.

Example workflow (CI) — Place under `.github/workflows/ci.yml` or use as a reference:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Tests
        run: flutter test --reporter expanded

      - name: Build macOS (optional)
        if: runner.os == 'macOS'
        run: flutter build macos
```

This is a minimal example that helps ensure PRs have passing tests and no new lints or analyzer warnings. You can add platform-specific runners or device matrix jobs for integration tests.
