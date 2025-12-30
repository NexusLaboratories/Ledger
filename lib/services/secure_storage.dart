import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  static final _secureStorage = FlutterSecureStorage();

  static Future<void> setValue({
    required String key,
    required String value,
  }) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<dynamic> getValue({required String key}) async {
    final value = await _secureStorage.read(key: key);
    return value;
  }

  static Future<void> clearValue({required String key}) async {
    await _secureStorage.delete(key: key);
  }
}
