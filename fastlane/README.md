# Fastlane Setup for Nexus Ledger

This directory contains Fastlane configuration for automating deployments and managing app metadata for F-Droid.

## Structure

```
fastlane/
├── Appfile                    # App configuration
├── Fastfile                   # Automation lanes
└── metadata/
    └── android/
        └── en-US/
            ├── title.txt              # App title (max 30 chars)
            ├── short_description.txt  # Short description (max 80 chars)
            ├── full_description.txt   # Full app description (max 4000 chars)
            ├── changelogs/           # Version changelogs
            └── images/
                ├── phoneScreenshots/      # Phone screenshots
                └── tenInchScreenshots/    # Tablet screenshots
```

## F-Droid Integration

F-Droid will automatically read metadata from the `metadata/android/en-US/` directory:

- **title.txt**: The app name shown in F-Droid
- **short_description.txt**: Brief description shown in search results
- **full_description.txt**: Detailed description shown on the app page
- **changelogs/**: Version-specific changelogs (named with version codes)
- **images/**: Screenshots for phone and tablet

## Adding Screenshots

1. Take screenshots of your app (PNG or JPG format)
2. Resize to appropriate dimensions:
   - Phone: 1080x1920 or similar 9:16 aspect ratio
   - Tablet: 1536x2048 or similar 4:3 aspect ratio
3. Name them sequentially: 1.png, 2.png, 3.png, etc.
4. Place in the appropriate directory:
   - `metadata/android/en-US/images/phoneScreenshots/`
   - `metadata/android/en-US/images/tenInchScreenshots/`

## Adding Changelogs

Create a new file for each version in `metadata/android/en-US/changelogs/`:

```
changelogs/
├── 1.txt    # Changelog for version code 1
├── 2.txt    # Changelog for version code 2
└── 3.txt    # Changelog for version code 3
```

The version code is defined in your `android/app/build.gradle.kts` file.

## Running Fastlane Locally

Install Fastlane:
```bash
gem install fastlane
```

Run a lane:
```bash
cd fastlane
fastlane android test
```

## More Information

- [Fastlane Documentation](https://docs.fastlane.tools)
- [F-Droid Metadata Documentation](https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/)
