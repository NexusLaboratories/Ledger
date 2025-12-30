import 'package:flutter/material.dart';
import 'package:ledger/models/activity.dart';
import 'package:ledger/components/activities/activity_helpers.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/components/ui/common/icon_container.dart';

class ActivityItem extends StatelessWidget {
  final Activity activity;
  final String dateFormatKey;

  const ActivityItem({
    super.key,
    required this.activity,
    required this.dateFormatKey,
  });

  @override
  Widget build(BuildContext context) {
    final icon = activity.icon;
    final color = activity.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          IconContainer(
            icon: icon,
            color: color,
            iconSize: 16,
            padding: 8,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${activity.description} • ${DateFormatter.formatWithKeyOrPattern(activity.timestamp, dateFormatKey)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.metadata['amount'] ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
