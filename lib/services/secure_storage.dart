import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  static final _secureStorage = FlutterSecureStorage();

  static Future<void> setValue({
    required String key,
    required String value,
  }) async {
    try {
      await _secureStorage
          .write(key: key, value: value)
          .timeout(const Duration(milliseconds: 250), onTimeout: () => null);
    } catch (_) {
      // Swallow storage errors in tests or environments without a
      // platform implementation to avoid blocking UI/tests.
    }
  }

  static Future<dynamic> getValue({required String key}) async {
    try {
      final value = await _secureStorage
          .read(key: key)
          .timeout(const Duration(milliseconds: 250), onTimeout: () => null);
      return value;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearValue({required String key}) async {
    try {
      await _secureStorage
          .delete(key: key)
          .timeout(const Duration(milliseconds: 250), onTimeout: () => null);
    } catch (_) {
      // Ignore
    }
  }
}
