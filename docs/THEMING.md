# Theming Guide

## Quick Start

```dart
import 'package:ledger/presets/app_theme_extension.dart';

// Use colors
Text('Hello', style: TextStyle(color: context.appColors.textSecondary))
```

## Available Colors

- **Text**: `textPrimary`, `textSecondary`, `textMuted`
- **UI**: `cardBackground`, `borderPrimary`, `borderSecondary`
- **Status**: `positive`, `negative`, `warning`
- **Budget**: `budgetHealthy`, `budgetWarning`, `budgetOverspent`
- **Grey**: `grey200`, `grey400`, `grey600`
- **Other**: `iconSecondary`, `categoryPalette`

## Migration

**Old way:**
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
color: isDark ? Colors.grey[400] : Colors.grey[600]
```

**New way:**
```dart
color: context.appColors.textSecondary
```

## Examples

See [empty_state.dart](../lib/components/empty_state.dart), [budget_progress_row.dart](../lib/components/budget_progress_row.dart), and [report_stat_card.dart](../lib/components/report_stat_card.dart) for usage examples.
