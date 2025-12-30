import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ledger/models/notification.dart' as model;
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/models/transaction.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

abstract class AbstractNotificationService {
  Future<void> initialize();
  Future<void> showNotification({
    required String title,
    required String body,
    required model.NotificationType type,
    model.NotificationPriority priority = model.NotificationPriority.normal,
    Map<String, dynamic>? metadata,
  });
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required model.NotificationType type,
    model.NotificationPriority priority = model.NotificationPriority.normal,
    Map<String, dynamic>? metadata,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  Future<void> checkBudgetThresholds();
  Future<void> checkTransactionAlerts(Transaction transaction);
  Future<bool> areNotificationsEnabled();
  Future<void> scheduleReportReminders();
  Future<void> cancelReportReminders();
}

class NotificationService implements AbstractNotificationService {
  NotificationService._internal();

  static NotificationService? _instance;
  factory NotificationService({TransactionService? transactionService}) {
    // Keep transactionService parameter for backwards compatibility
    // but we don't use it anymore
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'ledger_notifications';
  static const String _channelName = 'Ledger Notifications';
  static const String _channelDescription =
      'Notifications for budget and transaction alerts';

  @override
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e, stackTrace) {
      LoggerService.e('Failed to initialize notifications', e, stackTrace);
      throw NotificationException(
        'Failed to initialize notification service',
        e,
      );
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap - could navigate to relevant screen
    // For now, just log the payload (in production, use proper logging)
    // print('Notification tapped: ${response.payload}');
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    required model.NotificationType type,
    model.NotificationPriority priority = model.NotificationPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    LoggerService.i(
      'Showing notification | Type: $type | Priority: $priority | Title: "$title"',
    );
    try {
      if (!await areNotificationsEnabled()) {
        LoggerService.i('Notifications disabled, skipping');
        return;
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
          );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: metadata?.toString(),
      );
    } catch (e, stackTrace) {
      LoggerService.e('Failed to show notification', e, stackTrace);
      // Don't throw - notifications shouldn't crash the app
    }
  }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required model.NotificationType type,
    model.NotificationPriority priority = model.NotificationPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!await areNotificationsEnabled()) return;

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
          );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Use timezone for proper scheduling
      if (scheduledTime.isBefore(DateTime.now())) {
        return; // Don't schedule past notifications
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: metadata?.toString(),
      );
    } catch (e, stackTrace) {
      LoggerService.e('Failed to schedule notification', e, stackTrace);
      // Don't throw - notifications shouldn't crash the app
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<void> checkBudgetThresholds() async {
    try {
      // Check if budget notifications are enabled
      final budgetNotificationsEnabled =
          await UserPreferenceService.isBudgetNotificationsEnabled();
      if (!budgetNotificationsEnabled) return;

      // Get user's threshold preferences
      final notify50 =
          await UserPreferenceService.isBudgetNotification50Enabled();
      final notify80 =
          await UserPreferenceService.isBudgetNotification80Enabled();
      final notify90 =
          await UserPreferenceService.isBudgetNotification90Enabled();

      // Get all active budgets
      final budgetService = BudgetService();
      final budgets = await budgetService.fetchBudgets('local');

      // Check each budget's progress
      for (final budget in budgets) {
        if (!budget.isActive) continue;

        final progress = await budgetService.calculateProgress(budget);
        final percent = progress.percent;

        // Determine which threshold was crossed
        String? thresholdMessage;
        model.NotificationPriority priority = model.NotificationPriority.normal;

        if (percent >= 90 && notify90) {
          thresholdMessage = '90%';
          priority = model.NotificationPriority.urgent;
        } else if (percent >= 80 && notify80) {
          thresholdMessage = '80%';
          priority = model.NotificationPriority.high;
        } else if (percent >= 50 && notify50) {
          thresholdMessage = '50%';
          priority = model.NotificationPriority.normal;
        }

        if (thresholdMessage != null) {
          await showNotification(
            title: 'Budget Alert: ${budget.name}',
            body:
                'You\'ve reached $thresholdMessage of your budget (${percent.toStringAsFixed(1)}% used)',
            type: model.NotificationType.budgetExceeded,
            priority: priority,
            metadata: {
              'budgetId': budget.id,
              'percent': percent,
              'spent': progress.spent,
              'limit': budget.amount,
            },
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService.e('Failed to check budget thresholds', e, stackTrace);
      // Don't throw - this is a background check
    }
  }

  @override
  Future<void> checkTransactionAlerts(Transaction transaction) async {
    // Check for large transactions or unusual spending patterns
    const largeTransactionThreshold = 500.0;

    if (transaction.amount >= largeTransactionThreshold &&
        transaction.type == TransactionType.expense) {
      await showNotification(
        title: 'Large Transaction Alert',
        body:
            'You made a large expense: ${transaction.title} - \$${transaction.amount}',
        type: model.NotificationType.transactionAlert,
        priority: model.NotificationPriority.high,
        metadata: {
          'transactionId': transaction.id,
          'amount': transaction.amount,
        },
      );
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return await UserPreferenceService.isNotificationsEnabled();
  }

  @override
  Future<void> scheduleReportReminders() async {
    // Cancel existing report reminders first
    await cancelReportReminders();

    final isEnabled = await UserPreferenceService.isReportReminderEnabled();
    if (!isEnabled) return;

    final frequency = await UserPreferenceService.getReportReminderFrequency();

    // Calculate next reminder date based on frequency
    final now = DateTime.now();
    final nextReminder = DateTime(
      now.year,
      now.month + frequency,
      1, // First day of the month
      9, // 9 AM
      0,
    );

    // Schedule the notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      999, // Fixed ID for report reminders
      'Monthly Report Reminder',
      'Time to review your financial reports!',
      tz.TZDateTime.from(nextReminder, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  @override
  Future<void> cancelReportReminders() async {
    await _flutterLocalNotificationsPlugin.cancel(999);
  }
}
