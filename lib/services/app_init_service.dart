import 'package:flutter/material.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/theme_service.dart';
import 'package:ledger/services/biometric_service.dart';
import 'package:ledger/services/logger_service.dart';

abstract class AppInitializationService {
  static Future<void> initialiseApp() async {
    DatabaseService dbService = getIt<DatabaseService>();

    // Database initialization (fail-safe: don't block app if DB initialization
    // or opening fails — log and continue so app can still display a helpful UI.)
    try {
      await dbService.init();
      // Attempt to open DB in normal app flows where the plugin is present.
      // If a password is set, respect it. If not, attempt open as well.
      try {
        final passwordSet = await UserPreferenceService.isDatabasePasswordSet();
        if (passwordSet) {
          // Check if biometric unlock is enabled and supported
          final useBiometric = await UserPreferenceService.isUseBiometric();
          final biometricSupported = await BiometricService.isDeviceSupported();

          if (useBiometric && biometricSupported) {
            final authenticated = await BiometricService.authenticate(
              localizedReason: 'Authenticate to access your financial data',
              useErrorDialogs: true,
              stickyAuth: true,
            );

            if (authenticated) {
              await dbService.openDB();
            }
            // Don't open DB if auth failed - user will need to authenticate via password prompt in dashboard
          } else {
            // Biometric not enabled or not supported, open DB (password prompt will show in dashboard if needed)
            await dbService.openDB();
          }
        } else {
          // Try opening DB even if no password is set — this avoids leaving the
          // DB unopened on normal runs. If it fails, it's safe — we fall back.
          await dbService.openDB();
        }

        // Run database migrations to ensure all tables and columns exist
        try {
          await dbService.ensureMigrations();
        } catch (e) {
          LoggerService.e('Database migration failed', e);
        }
      } catch (e) {
        // Opening DB failed; continue without blocking the app. The app should
        // still run, and UI will handle DB-unavailable flows gracefully.
        LoggerService.w('Database open failed during initialization', e);
      }
    } catch (e) {
      // Database initialization failed; continue startup but don't block the
      // application from showing a UI. This avoids a blank screen when the
      // database plugin fails to initialize in certain environments.
      LoggerService.e('Database initialization failed', e);
    }

    // Apply saved theme preferences
    final themeService = getIt<ThemeService>();
    try {
      final matchTheme = await UserPreferenceService.isMatchTheme();
      final darkMode = await UserPreferenceService.isDarkMode();
      if (matchTheme) {
        themeService.setThemeMode(ThemeMode.system);
      } else {
        themeService.setThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
      }
    } catch (_) {
      // Ignore pref loading errors; default to system
      themeService.setThemeMode(ThemeMode.system);
    }
  }
}
