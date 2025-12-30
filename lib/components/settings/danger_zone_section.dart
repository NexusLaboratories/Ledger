import 'package:flutter/material.dart';
import 'package:ledger/components/settings/settings_list_tile.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/constants/ui_constants.dart';

class DangerZoneSection extends StatelessWidget {
  final VoidCallback onResetDatabase;

  const DangerZoneSection({super.key, required this.onResetDatabase});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomColors.negative.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: CustomColors.negative.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SettingsListTile(
        icon: Icons.delete_forever_outlined,
        iconColor: CustomColors.red400,
        title: UIConstants.resetDatabase,
        subtitle: UIConstants.resetDatabaseSubtitle,
        trailing: Icon(Icons.arrow_forward_ios, color: CustomColors.red400),
        onTap: onResetDatabase,
      ),
    );
  }
}
