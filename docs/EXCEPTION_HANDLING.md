# Exception Handling Implementation

This document describes the comprehensive exception handling system implemented throughout the Ledger application.

## Overview

The app now has a robust, multi-layered exception handling system that:
- Catches and logs all errors centrally
- Provides user-friendly error messages
- Offers retry mechanisms where appropriate
- Prevents app crashes from unhandled exceptions
- Maintains error context throughout the stack

## Components

### 1. Custom Exception Types (`lib/presets/exceptions.dart`)

#### Database Exceptions
- `DatabaseException` - Base class for all database errors
- `DatabaseNotOpenException` - Database connection not established
- `DatabaseInitializationException` - Failed to initialize database
- `TableCreationException` - Table creation failed
- `DatabaseQueryException` - Query execution failed
- `DatabaseInsertException` - Insert operation failed
- `DatabaseUpdateException` - Update operation failed
- `DatabaseDeleteException` - Delete operation failed
- `PasswordNotFoundException` - Database password not configured
- `AccountNotFoundException` - Requested account doesn't exist

#### Service Exceptions
- `ServiceException` - Base class for service-level errors
- `ValidationException` - Data validation failed
- `NetworkException` - Network-related errors
- `AuthenticationException` - Authentication/authorization errors
- `ImportException` - Data import failed
- `ExportException` - Data export failed
- `FileOperationException` - File I/O errors
- `ParseException` - Data parsing errors
- `BiometricException` - Biometric authentication errors
- `NotificationException` - Notification system errors
- `CurrencyConversionException` - Currency conversion errors

### 2. Error Handler Service (`lib/services/error_handler_service.dart`)

Central service for managing all error handling with the following features:

#### User Feedback
```dart
// Show error in a SnackBar
ErrorHandlerService.showErrorSnackBar(context, 'Error message');

// Show success message
ErrorHandlerService.showSuccessSnackBar(context, 'Success message');

// Show detailed error dialog
ErrorHandlerService.showErrorDialog(
  context,
  title: 'Error',
  message: 'Something went wrong',
  details: 'Technical details...',
  onRetry: () => retryOperation(),
);
```

#### Error Message Conversion
```dart
// Convert any exception to user-friendly message
final message = ErrorHandlerService.getErrorMessage(error);
```

#### Error Wrapping
```dart
// Wrap async operations with automatic error handling
final result = await ErrorHandlerService.wrapAsync(
  () => someAsyncOperation(),
  context: 'Loading user data',
  uiContext: context,
  showErrorToUser: true,
  onRetry: () => retry(),
);

// Wrap synchronous operations
final result = ErrorHandlerService.wrapSync(
  () => someSyncOperation(),
  context: 'Processing data',
  uiContext: context,
);
```

#### Centralized Error Handling
```dart
// Log and optionally show error to user
await ErrorHandlerService.handleError(
  error,
  stackTrace,
  context: 'Creating transaction',
  uiContext: context,
  showSnackBar: true,
  onRetry: () => retry(),
);
```

### 3. UI Error Components (`lib/components/ui/common/error_display.dart`)

#### ErrorDisplay Widget
Displays errors in a consistent, user-friendly way:
```dart
ErrorDisplay(
  message: 'Failed to load data',
  onRetry: () => reload(),
  compact: false, // Use compact mode for inline errors
)
```

#### AsyncOperationBuilder Widget
Handles async operations with built-in loading, error, and success states:
```dart
AsyncOperationBuilder<List<Transaction>>(
  operation: () => transactionService.getAllTransactions(),
  operationContext: 'Loading transactions',
  builder: (context, transactions) {
    return TransactionList(transactions: transactions);
  },
  loadingBuilder: (context) => CustomLoadingIndicator(),
  errorBuilder: (context, error) => CustomErrorWidget(error),
)
```

#### Context Extensions
Convenient extensions for error handling:
```dart
context.showError('Something went wrong');
context.showSuccess('Operation completed');
await context.showErrorDialog(
  title: 'Error',
  message: 'Details...',
  onRetry: () => retry(),
);
```

## Implementation Patterns

### Service Layer

All services should wrap operations in try-catch blocks:

```dart
class MyService {
  Future<void> createItem(Item item) async {
    try {
      // Perform operation
      await _dbService.insert(item);
      
      // Log success
      LoggerService.i('Item created: ${item.id}');
    } catch (e, stackTrace) {
      // Log error with context
      LoggerService.e('Failed to create item', e, stackTrace);
      
      // Rethrow or wrap in custom exception
      throw ServiceException('Failed to create item', e);
    }
  }
}
```

### UI Layer

#### Form Submissions
```dart
Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isSubmitting = true);
  
  try {
    await _service.saveData(data);
    
    if (mounted) {
      context.showSuccess('Data saved successfully');
      Navigator.pop(context);
    }
  } catch (e, stackTrace) {
    LoggerService.e('Failed to save data', e, stackTrace);
    
    if (mounted) {
      final errorMessage = ErrorHandlerService.getErrorMessage(e);
      context.showError(errorMessage);
    }
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
```

#### Data Loading
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late Future<List<Item>> _itemsFuture;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    setState(() {
      _itemsFuture = _service.fetchItems();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AsyncOperationBuilder<List<Item>>(
      operation: () => _itemsFuture,
      operationContext: 'Loading items',
      builder: (context, items) {
        return ItemList(items: items);
      },
    );
  }
}
```

### Database Layer

Database operations already wrap all CRUD operations with appropriate exceptions:

```dart
// Insert operation
Future<int> insert(String table, Map<String, dynamic> values) async {
  try {
    await _ensureDBOpen();
    return await _db!.insert(table, values);
  } catch (e) {
    throw DatabaseInsertException(e.toString());
  }
}
```

## Error Recovery Strategies

### Retry Mechanism
Most error messages include a retry option:
```dart
ErrorHandlerService.showErrorSnackBar(
  context,
  'Failed to load data',
  action: SnackBarAction(
    label: 'Retry',
    onPressed: () => _loadData(),
  ),
);
```

### Graceful Degradation
Services return safe defaults on error:
```dart
Future<List<Item>> fetchItems() async {
  try {
    return await _dbService.query();
  } catch (e, stackTrace) {
    LoggerService.e('Failed to fetch items', e, stackTrace);
    return []; // Return empty list instead of crashing
  }
}
```

### User Guidance
Error messages provide actionable guidance:
- Database errors suggest checking settings or restarting
- Network errors suggest checking connection
- Validation errors explain what's wrong with input

## Logging Integration

All exceptions are logged through `LoggerService`:

```dart
LoggerService.e('Operation failed', error, stackTrace);
```

This ensures:
- All errors are tracked
- Stack traces are preserved
- Error context is maintained
- Production errors can be monitored

## Testing Error Handling

### Unit Tests
```dart
test('should handle database errors gracefully', () async {
  // Arrange
  when(mockDb.insert(any, any)).thenThrow(Exception('DB error'));
  
  // Act & Assert
  expect(
    () => service.createItem(item),
    throwsA(isA<DatabaseInsertException>()),
  );
});
```

### Widget Tests
```dart
testWidgets('should show error message on failure', (tester) async {
  // Arrange
  when(mockService.fetchData()).thenThrow(Exception('Error'));
  
  // Act
  await tester.pumpWidget(MyWidget());
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Failed to load data'), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
});
```

## Best Practices

1. **Always catch specific exceptions first**
   ```dart
   try {
     // operation
   } on DatabaseException catch (e) {
     // handle database errors
   } on FormatException catch (e) {
     // handle format errors
   } catch (e) {
     // handle all other errors
   }
   ```

2. **Always log errors with context**
   ```dart
   LoggerService.e('Failed to create transaction: $title', e, stackTrace);
   ```

3. **Use custom exceptions for domain errors**
   ```dart
   throw ValidationException('Invalid amount: must be positive');
   ```

4. **Check widget mounting before showing UI**
   ```dart
   if (mounted) {
     context.showError(message);
   }
   ```

5. **Provide retry mechanisms for transient errors**
   ```dart
   ErrorHandlerService.showErrorSnackBar(
     context,
     message,
     action: SnackBarAction(label: 'Retry', onPressed: retry),
   );
   ```

6. **Clean up resources in finally blocks**
   ```dart
   try {
     await operation();
   } catch (e) {
     handleError(e);
   } finally {
     cleanup();
   }
   ```

## Updated Files

### New Files
- `lib/services/error_handler_service.dart` - Centralized error handling
- `lib/components/ui/common/error_display.dart` - Error UI components
- `docs/EXCEPTION_HANDLING.md` - This documentation

### Enhanced Files
- `lib/presets/exceptions.dart` - Added more exception types
- `lib/services/biometric_service.dart` - Added exception handling
- `lib/services/notification_service.dart` - Added exception handling
- `lib/services/import_service.dart` - Added exception handling
- `lib/services/export_service.dart` - Added exception handling
- `lib/modals/transaction_form_modal.dart` - Improved error handling
- All database services already had proper exception handling

### Existing Files with Good Exception Handling
- `lib/services/database/core_db_service.dart` - Already comprehensive
- `lib/services/account_service.dart` - Already using try-catch
- `lib/services/transaction_service.dart` - Already using try-catch
- `lib/main.dart` - Already has global error handlers

## Future Enhancements

1. **Error Analytics**: Integrate with analytics service to track error rates
2. **Offline Support**: Better handling of offline scenarios
3. **Error Recovery**: Automatic retry with exponential backoff
4. **User Reporting**: Allow users to report errors with context
5. **Error Boundaries**: Implement error boundary widgets for better isolation
