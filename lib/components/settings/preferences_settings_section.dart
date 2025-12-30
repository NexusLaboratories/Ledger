import 'package:flutter/material.dart';
import 'package:ledger/components/settings/settings_list_tile.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/constants/ui_constants.dart';
import 'package:ledger/presets/routes.dart';
import 'package:ledger/presets/currencies.dart';

class PreferencesSettingsSection extends StatelessWidget {
  final String defaultCurrency;
  final String dateFormatKey;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onDateFormatChanged;

  const PreferencesSettingsSection({
    super.key,
    required this.defaultCurrency,
    required this.dateFormatKey,
    required this.onCurrencyChanged,
    required this.onDateFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsListTile(
          icon: Icons.attach_money,
          title: UIConstants.defaultCurrency,
          trailing: InkWell(
            onTap: () async {
              final selected = await showDialog<String?>(
                context: context,
                builder: (dialogContext) {
                  String query = '';

                  // Create a sorted list of entries to present (sorted by currency code)
                  final entries = supportedCurrencies.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  return StatefulBuilder(
                    builder: (context, setState) {
                      final filtered = entries.where((e) {
                        final q = query.trim().toLowerCase();
                        if (q.isEmpty) return true;
                        return e.key.toLowerCase().contains(q) ||
                            e.value.toLowerCase().contains(q);
                      }).toList();

                      return AlertDialog(
                        title: const Text('Select currency'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'Search code or currency name',
                                ),
                                onChanged: (v) => setState(() => query = v),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: filtered.isEmpty
                                    ? const Center(child: Text('No results'))
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: filtered.length,
                                        itemBuilder: (context, idx) {
                                          final item = filtered[idx];
                                          return ListTile(
                                            title: Text(item.key),
                                            subtitle: Text(item.value),
                                            onTap: () => Navigator.of(
                                              context,
                                            ).pop(item.key),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (selected != null && selected != defaultCurrency) {
                onCurrencyChanged(selected);
                await UserPreferenceService.setDefaultCurrency(value: selected);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  defaultCurrency.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        SettingsListTile(
          icon: Icons.calendar_today,
          title: UIConstants.dateFormat,
          trailing: DropdownButton<String>(
            value: dateFormatKey,
            underline: const SizedBox(),
            items: DateFormats.keys
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(
                      DateFormatter.formatWithKeyOrPattern(DateTime.now(), k),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value != null) {
                onDateFormatChanged(value);
                await DateFormatService.setFormat(value);
              }
            },
          ),
        ),
        const Divider(height: 1),
        SettingsListTile(
          icon: Icons.school,
          title: UIConstants.startTutorial,
          showChevron: false,
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.tutorial);
          },
        ),
      ],
    );
  }
}
