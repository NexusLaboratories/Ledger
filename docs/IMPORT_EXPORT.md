# Import/Export Feature

## Overview

The Ledger app provides a complete data import/export system that allows users to backup and restore their financial data in a human-readable JSON format.

## Features

### Export
- Exports all app data (accounts, transactions, categories, tags, budgets)
- Outputs human-readable, pretty-printed JSON
- Includes metadata (format version, timestamp, app version)
- Share via native share dialog (email, cloud storage, etc.)
- Automatic file naming with timestamp

### Import
- Pick JSON files from device storage
- Two import modes:
  - **Merge**: Adds imported data to existing data
  - **Replace**: Deletes all existing data and imports fresh
- Format validation and version checking
- Detailed import statistics
- Migration support for future format versions
- Error handling with user-friendly messages

## File Format

### Structure

```json
{
  "formatVersion": 1,
  "generatedAt": "2025-12-22T12:34:56.789Z",
  "appVersion": "1.0.0",
  "data": {
    "accounts": [...],
    "transactions": [...],
    "categories": [...],
    "tags": [...],
    "budgets": [...]
  }
}
```

### Format Version

The `formatVersion` field indicates the structure of the export file:

- **Version 1** (current): Initial format with all core entities

Future versions may introduce changes. The import service handles migration automatically.

### Metadata Fields

- `formatVersion` (int): Format version number
- `generatedAt` (ISO 8601 string): UTC timestamp of export
- `appVersion` (string): App version that created the export

### Data Fields

Each entity array contains the JSON representation of the model:

#### Accounts
```json
{
  "account_id": "uuid",
  "user_id": "local",
  "account_name": "Cash",
  "currency": "USD",
  "account_description": "Daily cash expenses",
  "balance": 1000.0,
  "created_at": 1234567890,
  "updated_at": 1234567890
}
```

#### Transactions
```json
{
  "transaction_id": "uuid",
  "transaction_title": "Groceries",
  "account_id": "account-uuid",
  "category_id": "category-uuid",
  "type": 1,
  "amount": 50.0,
  "date": 1234567890,
  "transaction_note": "Weekly shopping"
}
```

#### Categories
```json
{
  "category_id": "uuid",
  "user_id": "local",
  "parent_category_id": null,
  "category_name": "Food",
  "category_description": "Food and dining"
}
```

#### Tags
```json
{
  "tag_id": "uuid",
  "user_id": "local",
  "parent_tag_id": null,
  "tag_name": "Essential",
  "tag_description": "Essential expenses",
  "tag_color": 4294198070
}
```

#### Budgets
```json
{
  "budget_id": "uuid",
  "user_id": "local",
  "category_id": "category-uuid",
  "budget_name": "Monthly Food Budget",
  "amount": 500.0,
  "period": 0,
  "start_date": 1234567890,
  "end_date": null,
  "is_active": 1,
  "created_at": 1234567890,
  "updated_at": 1234567890
}
```

## Usage

### From Settings Screen

1. Navigate to **Settings** from the drawer menu
2. Scroll to the **Data Management** section

#### To Export Data:
1. Tap **Export Data**
2. Wait for the export to complete
3. Choose where to share/save the file (email, cloud storage, etc.)

#### To Import Data:
1. Tap **Import Data**
2. Choose **Merge** (keeps existing data) or **Replace** (deletes existing data)
3. Select a JSON file from your device
4. Review the import statistics
5. Data is immediately available in the app

### Programmatic Usage

#### Export

```dart
import 'package:ledger/services/export_service.dart';

// Export and get file
final file = await ExportService.exportData();

// Export and share immediately
await ExportService.exportAndShare();
```

#### Import

```dart
import 'package:ledger/services/import_service.dart';
import 'dart:io';

// Import with file picker
final result = await ImportService.importData(replaceAll: false);

// Import from specific file
final file = File('/path/to/export.json');
final result = await ImportService.importFromFile(file, replaceAll: true);

// Check result
if (result.success) {
  print('Imported: ${result.stats}');
} else {
  print('Error: ${result.message}');
}
```

## Migration Strategy

When the format version changes, the import service automatically migrates data:

```dart
static Map<String, dynamic> _migrateData(Map<String, dynamic> json) {
  final version = json['formatVersion'] as int;

  switch (version) {
    case 1:
      return json; // Current version, no migration
    case 2:
      // Future: migrate from v1 to v2
      return _migrateV1toV2(json);
    default:
      return json;
  }
}
```

## Security & Privacy

### What's Exported
- All financial data (transactions, accounts, budgets, etc.)
- No passwords or authentication tokens
- No biometric data
- User ID defaults to "local" for privacy

### Recommendations
1. **Encrypt sensitive exports**: Store in encrypted cloud storage
2. **Secure sharing**: Use secure channels (encrypted email, private cloud)
3. **Regular backups**: Export weekly or after major changes
4. **Verify imports**: Review import statistics before proceeding
5. **Test restore**: Periodically test import functionality

### What's NOT Exported
- Database password
- Biometric authentication settings
- User preferences (theme, notifications)
- App state (current screen, filters)

## Error Handling

The import service validates data and provides clear error messages:

| Error | Cause | Solution |
|-------|-------|----------|
| "Missing format version" | Invalid JSON structure | Re-export data from app |
| "Unsupported format version" | Export from newer app version | Update the app |
| "Import failed" | Corrupted file or invalid data | Try re-exporting data |
| "Import cancelled" | User cancelled file picker | Start import again |

## Testing

Unit tests cover:
- Export format validation
- Import format validation
- Round-trip consistency (export → import → same data)
- Merge vs. replace modes
- Error handling
- Migration logic

Run tests:
```bash
flutter test test/services/export_import_test.dart
```

## Best Practices

### For Users
1. Export before major changes
2. Store backups in multiple locations
3. Test imports on non-critical data first
4. Review import statistics carefully

### For Developers
1. Never change `formatVersion` without migration code
2. Always maintain backward compatibility
3. Test migrations thoroughly
4. Document format changes in this file

## Troubleshooting

### Export fails
- Check device storage space
- Ensure app has file write permissions
- Try restarting the app

### Import fails
- Verify JSON file is valid
- Check format version compatibility
- Ensure file isn't corrupted
- Try smaller data sets

### Data missing after import
- Check import mode (merge vs. replace)
- Verify source file has complete data
- Review import statistics for counts

## Future Enhancements

Potential improvements:
- [ ] Selective export (date range, account, category)
- [ ] Encrypted exports (password-protected)
- [ ] Automatic cloud backup
- [ ] Scheduled exports
- [ ] Export to CSV/PDF formats
- [ ] Import from other finance apps
- [ ] Incremental backups (only changes)

## Related Documentation

- [Architecture](ARCHITECTURE.md)
- [Data Safety](DATA_SAFETY.md)
- [Development Guide](DEVELOPMENT.md)
