import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/models/transaction_tag.dart';

void registerCommonFallbacks() {
  registerFallbackValue(Account(id: 'f', name: 'f'));
  registerFallbackValue(
    Transaction(
      title: 'f',
      amount: 1,
      accountId: 'a',
      date: DateTime.now(),
      type: TransactionType.income,
    ),
  );
  registerFallbackValue(Tag(id: 't', name: 't'));
  registerFallbackValue(Category(id: 'c', name: 'c'));
  registerFallbackValue(
    TransactionItem(id: 'i', transactionId: 't1', name: 'i'),
  );
  registerFallbackValue(TransactionTag(transactionId: 't1', tagId: 't'));
}

// Persistent store for secure storage mock, shared across all tests
final Map<String, String?> _mockSecureStorageStore = {};

// Register a basic mock handler for flutter_secure_storage plugin channel
// so tests that call SecureStorage methods don't hit platform channels.
// The store persists across multiple calls to this function.
void registerSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        final args = call.arguments as Map<dynamic, dynamic>?;
        switch (call.method) {
          case 'write':
            if (args != null) {
              _mockSecureStorageStore[args['key'] as String] =
                  args['value'] as String?;
            }
            return null;
          case 'read':
            if (args != null) {
              final k = args['key'] as String;
              if (k == 'default_currency') {
                return _mockSecureStorageStore[k] ?? 'USD';
              }
              return _mockSecureStorageStore[k];
            }
            return null;
          case 'delete':
            if (args != null) {
              _mockSecureStorageStore.remove(args['key'] as String);
            }
            return null;
          case 'readAll':
            return Map<String, dynamic>.from(_mockSecureStorageStore);
          default:
            return null;
        }
      });
}
