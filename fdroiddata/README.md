This folder contains F‑Droid metadata for Ledger (org.nexuslabs.ledger).

Steps to get this published to F‑Droid:

1. Create a tagged release in this repository, for example `v1.0.0`.
2. Ensure the repo builds with `cd ledger/android && ./gradlew assembleRelease` locally.
3. Optionally run a local fdroidserver build to reproduce issues.
4. Open a merge request against https://gitlab.com/fdroid/fdroiddata adding
   `fdroiddata/data/org.nexuslabs.ledger.yml`.

Notes:
- License: GPL‑3.0 (there is a LICENSE file at repo root).
- Application ID: `org.nexuslabs.ledger` (set in Gradle / Android manifest).
- If maintainers report build problems, address them and push fixes to
  the MR branch. If you want, I can try a local fdroidserver build and
  iterate on fixes.