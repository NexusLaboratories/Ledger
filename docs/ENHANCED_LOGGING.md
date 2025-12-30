# Enhanced Logging Implementation

## Overview

The app now has comprehensive logging that captures not just errors, but also important details, state information, and execution flow to help with debugging.

## What's Been Enhanced

### 1. **Error Handler Service**
Enhanced to log additional context with errors:
```dart
ErrorHandlerService.handleError(
  error,
  stackTrace,
  context: 'Creating transaction',
  additionalContext: {
    'transactionId': txId,
    'amount': amount,
    'accountId': accountId,
  },
);
```

The additional context is automatically included in log messages:
```
Creating transaction | Context: {transactionId: abc123, amount: 50.0, accountId: xyz456}
```

### 2. **Operation Lifecycle Logging**
All async operations now log their start and completion:
```dart
// Logs: "Starting: Loading user data"
final result = await ErrorHandlerService.wrapAsync(
  () => fetchUserData(),
  context: 'Loading user data',
);
// Logs: "Completed: Loading user data"
```

### 3. **Service-Level Detailed Logging**

#### Transaction Service
- **Creating**: Logs title, amount, type, and account
  ```
  Creating transaction: "Grocery Shopping" | Amount: $50.00 | Type: expense | Account: abc123
  Transaction created successfully: tx_456 | Tags: 3
  ```

- **Deleting**: Logs transaction details before deletion
  ```
  Deleting transaction: tx_456
  Transaction found: "Grocery Shopping" | Amount: $50.00 | Type: expense
  Transaction deleted and balance updated: tx_456
  ```

#### Account Service
- **Creating**: Logs name, currency, and icon
  ```
  Creating account: "Checking Account" | Currency: USD | Icon: wallet
  Resolved currency: USD
  Account created successfully: acc_789
  ```

- **Errors**: Include all relevant context
  ```
  Failed to create account: "Checking Account" | Currency: USD
  ```

#### Database Service (Core Operations)

##### Initialization
```
Initializing database service
Database path: /path/to/expense.db
Database password configured: true
Database service initialized successfully
```

##### Opening Database
```
Opening database...
Database already open
```

##### Migrations
```
Checking transaction table columns...
Transaction table columns: transaction_id, transaction_title, amount, date, ...
Adding transaction_note column...
Transaction table columns check complete
```

##### CRUD Operations
- **Insert**: Logs table name, keys, and result
  ```
  DB Insert | Table: transactions | Keys: transaction_id, title, amount, date, account_id
  DB Insert successful | Table: transactions | Row ID: 123
  ```

- **Update**: Logs table, keys, where clause, and rows affected
  ```
  DB Update | Table: accounts | Keys: balance, updated_at | Where: account_id = ?
  DB Update successful | Table: accounts | Rows affected: 1
  ```

- **Delete**: Logs table, where clause, and rows affected
  ```
  DB Delete | Table: transactions | Where: transaction_id = ? | Args: [tx_456]
  DB Delete successful | Table: transactions | Rows affected: 1
  ```

- **Query**: Logs table, where clause, and result count
  ```
  DB Query | Table: accounts | Where: user_id = ? | Args: [local]
  DB Query successful | Table: accounts | Results: 5 rows
  ```

#### Import/Export Service

##### Export
```
Starting data export...
Fetching data from database...
Accounts fetched: 5
Transactions fetched: 142
Categories fetched: 12
Tags fetched: 8
Budgets fetched: 3
Export completed: /path/to/ledger_export_20251230_143022.json
```

##### Import
```
Starting data import...
Importing data | Accounts: 5 | Transactions: 142 | Categories: 12 | Tags: 8 | Budgets: 3 | Mode: Replace
Import completed successfully | Total items: 170
```

#### Biometric Service
```
Biometric authentication attempt | Sticky: true | Error dialogs: true
Biometric support check: supported
Biometric authentication result: success
```

#### Notification Service
```
Showing notification | Type: budgetExceeded | Priority: high | Title: "Budget Alert"
Notifications disabled, skipping
```

### 4. **UI-Level Detailed Logging**

#### Transaction Form Modal
```
Loading accounts for transaction form...
Accounts loaded: 5
Selected account: acc_123

Loading categories for transaction form...
Categories loaded: 12

Loading tags for transaction form...
Tags loaded: 8

Creating new tag: "Shopping"
Tag created successfully: tag_789
Tag selected: tag_789

Submitting transaction form | Mode: Create | Type: expense | Account: acc_123
Transaction details | Amount: $50.00 | Items: 3 | Tags: 2
Items total mismatch | Items: $45.00 | Entered: $50.00
# OR on success:
Creating new transaction: tx_456
Persisting 3 transaction items...
Transaction created successfully: tx_456
```

## Log Levels Used

### 📘 Info (LoggerService.i)
- Operation start/completion
- Successful operations
- Important state changes
- Data counts and statistics
- User actions

**Examples:**
```
Starting data export...
Transaction created successfully: tx_456
Accounts loaded: 5
```

### ⚠️ Warning (LoggerService.w)
- Recoverable issues
- Validation failures
- Data inconsistencies
- Fallback scenarios

**Examples:**
```
Transaction not found for deletion: tx_456
Items total mismatch | Items: $45.00 | Entered: $50.00
Notifications disabled, skipping
```

### ❌ Error (LoggerService.e)
- Operation failures
- Exceptions caught
- System errors
- All errors include stack traces

**Examples:**
```
Failed to create transaction: "Grocery Shopping" | Amount: $50.00 | Account: acc_123
DB Insert failed | Table: transactions | Error: Database locked
Failed to load accounts for transaction form
```

### 🔍 Debug (LoggerService.d)
- Development-only logging
- Not written to file in release mode
- Technical implementation details

**Examples:**
```
AccountService: updating account acc_123
```

## Viewing Logs

### In Development
All logs appear in the console with appropriate formatting.

### In Production
Logs are written to a file at:
```
/path/to/app/documents/ledger_logs.txt
```

### Accessing Logs
```dart
// Get log file for sharing/viewing
final logFile = await LoggerService.getLogFile();

// Get logs as string
final logsString = await LoggerService.getLogsAsString();

// Clear logs
await LoggerService.clearLogs();
```

## Log Format

Each log entry includes:
- **Timestamp**: Precise time of log entry
- **Level**: Info, Warning, Error, Debug
- **Message**: Descriptive message with context
- **Error**: Exception details (if applicable)
- **Stack Trace**: Full stack trace for errors

Example log entry:
```
2025-12-30 14:30:22.456 [INFO] Creating transaction: "Grocery Shopping" | Amount: $50.00 | Type: expense | Account: acc_123
2025-12-30 14:30:22.789 [INFO] Transaction created successfully: tx_456 | Tags: 3
2025-12-30 14:30:23.012 [ERROR] Failed to create transaction: "Rent" | Amount: $1500.00 | Account: acc_789
DatabaseInsertException: Insert failed: Database is locked
Stack trace:
#0      DatabaseService.insert (package:ledger/services/database/core_db_service.dart:556)
#1      TransactionDBService.createTransaction (package:ledger/services/database/transaction_db_service.dart:42)
...
```

## Debugging with Logs

### Finding Issues
1. **Search for ERROR entries** - Shows all failures
2. **Look at preceding INFO entries** - Shows what led to the error
3. **Check parameter values** - All important data is logged
4. **Follow the timeline** - Timestamps show operation sequence

### Example Debug Session
```
14:30:20.123 [INFO] Loading accounts for transaction form...
14:30:20.456 [INFO] Accounts loaded: 5
14:30:20.789 [INFO] Submitting transaction form | Mode: Create | Type: expense | Account: acc_123
14:30:21.012 [INFO] Transaction details | Amount: $50.00 | Items: 0 | Tags: 2
14:30:21.234 [INFO] Creating new transaction: tx_456
14:30:21.456 [INFO] Creating transaction: "Grocery Shopping" | Amount: $50.00 | Type: expense | Account: acc_123
14:30:21.678 [INFO] DB Insert | Table: transactions | Keys: transaction_id, title, amount, ...
14:30:21.901 [ERROR] DB Insert failed | Table: transactions
DatabaseInsertException: Insert failed: UNIQUE constraint failed: transactions.transaction_id
```

From this log, we can see:
1. The form was loaded successfully
2. User tried to create a transaction
3. The transaction ID already existed (duplicate ID issue)
4. We know exactly which transaction ID caused the problem

## Benefits

1. **Complete Audit Trail**: Every operation is logged
2. **Rich Context**: All important parameters and state are captured
3. **Easy Debugging**: Can reconstruct exact sequence of events
4. **Production Diagnostics**: Logs available even in production builds
5. **Performance Tracking**: Can see how long operations take
6. **User Support**: Can ask users to share logs for bug reports

## Best Practices

1. **Always log operation start and completion**
   ```dart
   LoggerService.i('Starting expensive operation...');
   await doWork();
   LoggerService.i('Completed expensive operation');
   ```

2. **Include relevant context in error messages**
   ```dart
   LoggerService.e('Failed to save user: $userId | Role: $role', e, stackTrace);
   ```

3. **Use appropriate log levels**
   - Info for normal operations
   - Warning for recoverable issues
   - Error for failures

4. **Log important state changes**
   ```dart
   LoggerService.i('User logged in: $userId | Session: $sessionId');
   ```

5. **Include data counts and statistics**
   ```dart
   LoggerService.i('Loaded ${items.length} items in ${duration.inMilliseconds}ms');
   ```
