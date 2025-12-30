import 'package:flutter/material.dart';
import 'package:ledger/models/activity.dart';
import 'package:ledger/presets/theme.dart';

extension ActivityDisplay on Activity {
  bool get isExpense {
    final val = metadata['isExpense'];
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    if (val is num) return val != 0;
    return false;
  }

  IconData get icon {
    switch (type) {
      case ActivityType.transaction:
        return isExpense ? Icons.remove_circle : Icons.add_circle;
      case ActivityType.accountCreated:
      case ActivityType.accountUpdated:
        return Icons.account_balance;
      case ActivityType.categoryCreated:
      case ActivityType.categoryUpdated:
        return Icons.category;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.transaction:
        return isExpense ? CustomColors.negative : CustomColors.positive;
      case ActivityType.accountCreated:
      case ActivityType.accountUpdated:
        return CustomColors.darkBlue;
      case ActivityType.categoryCreated:
      case ActivityType.categoryUpdated:
        return CustomColors.lightBlue;
    }
  }
}
