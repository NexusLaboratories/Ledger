import 'package:flutter/foundation.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/services/user_preference_service.dart';

class DateFormatService {
  static final ValueNotifier<String> notifier = ValueNotifier<String>(
    DateFormats.defaultKey,
  );

  static Future<void> init() async {
    final key = await UserPreferenceService.getDateFormat();
    notifier.value = key;
  }

  static Future<void> setFormat(String key) async {
    await UserPreferenceService.setDateFormat(value: key);
    notifier.value = key;
  }
}
