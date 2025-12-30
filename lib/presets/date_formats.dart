class DateFormats {
  // Keys used to identify formats in storage
  static const String defaultKey = 'MMM_dd_yyyy';

  // Map of key -> pattern
  static const Map<String, String> patterns = {
    'MMM_dd_yyyy': 'MMM dd, yyyy', // Jan 01, 2025
    'dd_MMM_yyyy': 'dd MMM yyyy', // 01 Jan 2025
    'd_M_yyyy': 'd/M/yyyy', // 1/1/2025
    'yyyy_MM_dd': 'yyyy-MM-dd', // 2025-01-01
    'EEE_MMM_d_yyyy': 'EEE, MMM d, yyyy', // Wed, Jan 1, 2025
  };

  static String getPattern(String key) =>
      patterns[key] ?? patterns[defaultKey]!;

  static List<String> get keys => patterns.keys.toList();
}
