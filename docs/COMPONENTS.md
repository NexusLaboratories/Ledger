# Component System Documentation

## Enhanced Components

All components now support variants and options internally, making them more powerful and easier to use.

### CustomButton

**Variants**: `primary`, `secondary`, `destructive`, `ghost`
**Sizes**: `small`, `medium`, `large`

```dart
// Before: Manual styling everywhere
TextButton(
  onPressed: onSave,
  style: ButtonStyle(...lots of code...),
  child: Text('Save'),
)

// After: Simple and powerful
CustomButton(
  text: 'Save',
  onPressed: onSave,
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  icon: Icons.save,
  loading: isLoading,
  fullWidth: true,
)
```

### InfoCard

**Variants**: `info`, `success`, `warning`, `error`

Unified component for displaying messages with icons, colors, and optional actions. Supports both persistent cards and dismissible banners.

```dart
// Persistent info card
InfoCard(
  message: 'Your data has been saved',
  variant: InfoCardVariant.success,
  actionLabel: 'View',
  onTap: () => navigate(),
)

// Dismissible banner
InfoCard.banner(
  message: 'Low storage space',
  variant: InfoCardVariant.warning,
  onDismiss: () => hide(),
)
```

### SectionHeader

**Styles**: `accent`, `subtle`

Unified header component for both dashboard and settings sections.

```dart
// Accent style (dashboard)
SectionHeader(
  title: 'Recent Transactions',
  count: '12',
  onViewAll: () => showAll(),
)

// Subtle style (settings)
SectionHeader.settings(
  title: 'Security',
  color: CustomColors.red400, // optional
)
```

### LoadingIndicator

**Sizes**: `small`, `medium`, `large`

```dart
LoadingIndicator(
  message: 'Loading transactions...',
  size: LoadingSize.medium,
)
```

### IconContainer

**Sizes**: `small`, `medium`, `large`
**Shapes**: `circle`, `rounded`, `square`

```dart
IconContainer(
  icon: Icons.wallet,
  size: IconContainerSize.large,
  shape: IconContainerShape.circle,
  color: colors.positive,
)
```

### SettingsListTile & SettingsSwitchTile

```dart
SettingsListTile(
  icon: Icons.notifications,
  title: 'Notifications',
  subtitle: 'Manage your alerts',
  onTap: () => showSettings(),
)

SettingsSwitchTile(
  icon: Icons.dark_mode,
  title: 'Dark Mode',
  value: isDark,
  onChanged: (v) => toggleDark(v),
)
```

## Benefits

✅ **Self-contained**: Design logic lives in the component
✅ **Consistent**: Same styling across the app automatically
✅ **Powerful**: Rich options without complexity
✅ **Themeable**: Automatically adapts to light/dark mode
✅ **Less code**: Parent widgets don't handle styling
