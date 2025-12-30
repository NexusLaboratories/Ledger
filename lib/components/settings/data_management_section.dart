import 'package:flutter/material.dart';
import 'package:ledger/components/settings/settings_list_tile.dart';
import 'package:ledger/constants/ui_constants.dart';

/// Data management section for import/export
class DataManagementSection extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback? onShareLogs;

  const DataManagementSection({
    super.key,
    required this.onExport,
    required this.onImport,
    this.onShareLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsListTile(
          icon: Icons.upload_file,
          title: UIConstants.exportData,
          subtitle: UIConstants.exportDataSubtitle,
          onTap: onExport,
          showChevron: false,
        ),
        const Divider(height: 1),
        SettingsListTile(
          icon: Icons.download,
          title: UIConstants.importData,
          subtitle: UIConstants.importDataSubtitle,
          onTap: onImport,
          showChevron: false,
        ),
        if (onShareLogs != null) ...[
          const Divider(height: 1),
          SettingsListTile(
            icon: Icons.bug_report,
            title: 'Share Error Logs',
            subtitle: 'Send logs to support for troubleshooting',
            onTap: onShareLogs!,
            showChevron: false,
          ),
        ],
      ],
    );
  }
}
