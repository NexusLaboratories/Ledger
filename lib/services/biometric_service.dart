import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/logger_service.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e, stackTrace) {
      LoggerService.w('Platform error checking biometrics', e, stackTrace);
      return false;
    } catch (e, stackTrace) {
      LoggerService.e('Error checking biometrics', e, stackTrace);
      return false;
    }
  }

  /// Check if device is enrolled with biometrics (has fingerprint/face configured)
  static Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e, stackTrace) {
      LoggerService.w('Platform error checking device support', e, stackTrace);
      return false;
    } catch (e, stackTrace) {
      LoggerService.e('Error checking device support', e, stackTrace);
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e, stackTrace) {
      LoggerService.w('Platform error getting biometrics', e, stackTrace);
      return [];
    } catch (e, stackTrace) {
      LoggerService.e('Error getting available biometrics', e, stackTrace);
      return [];
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication was successful
  static Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your data',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    LoggerService.i(
      'Biometric authentication attempt | Sticky: $stickyAuth | Error dialogs: $useErrorDialogs',
    );
    try {
      final isSupported = await isDeviceSupported();
      LoggerService.i(
        'Biometric support check: ${isSupported ? "supported" : "not supported"}',
      );
      if (!isSupported) {
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow fallback to device PIN/password
        ),
      );

      LoggerService.i(
        'Biometric authentication result: ${authenticated ? "success" : "failed"}',
      );
      return authenticated;
    } on PlatformException catch (e, stackTrace) {
      LoggerService.w('Biometric authentication failed', e, stackTrace);
      throw BiometricException(
        'Biometric authentication failed: ${e.message}',
        e,
      );
    } catch (e, stackTrace) {
      LoggerService.e('Error during biometric authentication', e, stackTrace);
      throw BiometricException('Unexpected error during authentication', e);
    }
  }

  /// Stop authentication (cancel ongoing authentication)
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      // Silent fail for stopping authentication
    }
  }

  /// Get a human-readable description of available biometric types
  static String getBiometricTypeDescription(List<BiometricType> types) {
    if (types.isEmpty) return 'None available';

    final descriptions = <String>[];
    if (types.contains(BiometricType.face)) {
      descriptions.add('Face ID');
    }
    if (types.contains(BiometricType.fingerprint)) {
      descriptions.add('Fingerprint');
    }
    if (types.contains(BiometricType.iris)) {
      descriptions.add('Iris');
    }
    if (types.contains(BiometricType.strong)) {
      descriptions.add('Strong biometric');
    }
    if (types.contains(BiometricType.weak)) {
      descriptions.add('Weak biometric');
    }

    return descriptions.join(', ');
  }
}
