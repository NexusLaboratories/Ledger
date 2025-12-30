import 'package:uuid/uuid.dart';
import 'package:ledger/models/transaction_item.dart';

abstract class Utilities {
  static String generateUuid() => Uuid().v4();

  static double calculateItemsTotal(List<TransactionItem> items) {
    double total = 0.0;
    for (final it in items) {
      final qty = it.quantity ?? 1.0;
      final price = it.price ?? 0.0;
      total += qty * price;
    }
    return total;
  }
}
