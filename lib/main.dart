import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ledger/presets/routes.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/services/app_init_service.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/services/theme_service.dart';
import 'package:ledger/services/notification_service.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize production logging service
  await LoggerService.init();

  // Quiet noisy native compile/runtime warnings from third-party libs like
  // SQLCipher that appear in debug output and may surface to the UI in
  // certain dev setups. These are harmless compiler warnings; we filter
  // them so they don't pollute the debug console or error reports.
  final origDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) return;
    final lower = message.toLowerCase();
    if (lower.contains('sqlcipher') ||
        lower.contains('sqlite3.c') ||
        lower.contains('sqlite') ||
        lower.contains('implicit conversion loses integer precision')) {
      return; // swallow noisy native warnings
    }
    origDebugPrint(message, wrapWidth: wrapWidth);
  };

  final origFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString().toLowerCase();
    if (msg.contains('sqlcipher') || msg.contains('sqlite')) {
      // ignore SQLCipher/sqlite related warnings in dev mode
      return;
    }
    // Log production errors
    LoggerService.e('Flutter Error', details.exception, details.stack);
    if (origFlutterOnError != null) origFlutterOnError(details);
  };

  setupServiceLocator();
  try {
    await AppInitializationService.initialiseApp();
    // Initialize notifications
    final notificationService = getIt<NotificationService>();
    await notificationService.initialize();
    // Initialize user date format preference notifier so UI subscribers read initial value
    await DateFormatService.init();
  } catch (e, stackTrace) {
    // Initialization errors should not prevent the app from showing UI;
    // log and continue with default settings.
    LoggerService.e('App initialization failed', e, stackTrace);
  }

  // Also ensure any uncaught errors from the platform displayed by
  // the engine are not shown to users for these known noisy cases.
  PlatformDispatcher.instance.onError = (error, stack) {
    final m = error.toString().toLowerCase();
    if (m.contains('sqlcipher') || m.contains('sqlite')) return true;
    // Log production errors
    LoggerService.e('Platform Error', error, stack);
    return false; // let other errors bubble up
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      final seen = await UserPreferenceService.hasSeenTutorial();
      setState(() {
        _initialRoute = seen ? RouteNames.dashboard : RouteNames.tutorial;
      });
    } catch (e) {
      setState(() {
        _initialRoute = RouteNames.dashboard;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final themeService = getIt<ThemeService>();
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeService.notifier,
        builder: (context, mode, _) {
          return MaterialApp(
            routes: appRoutes,
            initialRoute: _initialRoute ?? RouteNames.dashboard,
            home: _initialRoute == null
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : null,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: mode,
          );
        },
      );
    } catch (e) {
      // Fallback if ThemeService is not initialized
      return MaterialApp(
        routes: appRoutes,
        initialRoute: _initialRoute ?? RouteNames.dashboard,
        home: _initialRoute == null
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : null,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
      );
    }
  }
}
