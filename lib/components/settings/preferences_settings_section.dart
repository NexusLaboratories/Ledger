import 'package:flutter/material.dart';
import 'package:ledger/components/settings/settings_list_tile.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/constants/ui_constants.dart';
import 'package:ledger/presets/routes.dart';

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
          trailing: DropdownButton<String>(
            value: defaultCurrency,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: UIConstants.usd,
                child: Text(UIConstants.usd),
              ),
              DropdownMenuItem(
                value: UIConstants.eur,
                child: Text(UIConstants.eur),
              ),
              DropdownMenuItem(
                value: UIConstants.gbp,
                child: Text(UIConstants.gbp),
              ),
              DropdownMenuItem(
                value: UIConstants.inr,
                child: Text(UIConstants.inr),
              ),
              DropdownMenuItem(
                value: UIConstants.jpy,
                child: Text(UIConstants.jpy),
              ),
              DropdownMenuItem(
                value: UIConstants.aud,
                child: Text(UIConstants.aud),
              ),
              DropdownMenuItem(
                value: UIConstants.cad,
                child: Text(UIConstants.cad),
              ),
            ],
            onChanged: (value) async {
              if (value != null) {
                onCurrencyChanged(value);
                await UserPreferenceService.setDefaultCurrency(value: value);
              }
            },
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
