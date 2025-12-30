import 'package:intl/intl.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;

/// Helpers to group transactions into human-friendly sections like Today, This Week,
/// This Month, and older months (e.g., November 2025).
class TransactionGrouping {
  static String _monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  // Normalize date to local date (no time) for comparisons
  static DateTime _toLocalDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      _toLocalDate(a) == _toLocalDate(b);

  static DateTime _startOfWeek(DateTime date) {
    // Use local date only. Week starts on Monday. DateTime.weekday: Monday=1, Sunday=7.
    final local = _toLocalDate(date);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  static bool _isSameWeek(DateTime a, DateTime b) {
    final startA = _startOfWeek(a);
    final startB = _startOfWeek(b);
    return startA.year == startB.year &&
        startA.month == startB.month &&
        startA.day == startB.day;
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Returns a map of sectionTitle => transactions for that section, ordered
  /// by date descending. The LinkedHashMap-like behavior is derived from Map literal insertion order.
  static Map<String, List<model_transaction.Transaction>> group(
    List<model_transaction.Transaction> transactions,
  ) {
    // Sort by date descending so newest groups come first
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<model_transaction.Transaction>> grouped = {};
    final now = DateTime.now();
    final nowDate = _toLocalDate(now);

    for (final t in transactions) {
      final tDate = _toLocalDate(t.date);
      String key;
      if (_isSameDay(tDate, nowDate)) {
        key = 'Today';
      } else if (_isSameWeek(tDate, nowDate)) {
        key = 'This Week';
      } else if (_isSameMonth(tDate, nowDate)) {
        key = 'This Month';
      } else {
        key = _monthYear(tDate);
      }
      grouped.putIfAbsent(key, () => []).add(t);
    }

    // Remove any empty sections (defensive programming)
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }
}
