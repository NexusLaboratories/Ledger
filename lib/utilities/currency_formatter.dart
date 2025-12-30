import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format an amount according to currency code.
  /// Accepts nullable [currencyCode] and defaults to 'USD'.
  /// Falls back to '`amount` `currency`' if the formatter cannot render a symbol.
  static String format(double amount, String currencyCode) {
    final code = (currencyCode.isEmpty) ? 'USD' : currencyCode;
    try {
      // Use named currency code; NumberFormat will attempt to use a symbol
      final format = NumberFormat.simpleCurrency(name: code);
      return format.format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(2)} $code';
    }
  }

  /// Compact formatting for axis labels (e.g. 1.2K, 3.5M) with currency symbol
  static String formatCompact(double amount, String currencyCode) {
    final code = (currencyCode.isEmpty) ? 'USD' : currencyCode;
    try {
      // Use compact currency formatter when available
      final compact = NumberFormat.compactSimpleCurrency(name: code);
      return compact.format(amount);
    } catch (_) {
      try {
        final rounded = NumberFormat.compact();
        return '${rounded.format(amount)} $code';
      } catch (__) {
        return '${amount.toStringAsFixed(0)} $code';
      }
    }
  }
}
