import 'package:intl/intl.dart';
import 'package:ledger/presets/date_formats.dart';

class DateFormatter {
  /// Synchronous formatting using provided [pattern].
  /// Pattern should match intl DateFormat patterns.
  static String formatWithPattern(DateTime d, String pattern) {
    try {
      return DateFormat(pattern).format(d);
    } catch (_) {
      // fallback to a safe format
      return DateFormat(
        DateFormats.getPattern(DateFormats.defaultKey),
      ).format(d);
    }
  }

  /// Helper to format using a format key (from DateFormats) or a raw pattern.
  static String formatWithKeyOrPattern(DateTime d, String keyOrPattern) {
    final pattern = DateFormats.patterns.containsKey(keyOrPattern)
        ? DateFormats.getPattern(keyOrPattern)
        : keyOrPattern;
    return formatWithPattern(d, pattern);
  }
}
