import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? margin;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding:
          margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: colors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderPrimary),
            ),
            child: Column(children: _addDividers(children, colors)),
          ),
        ],
      ),
    );
  }

  List<Widget> _addDividers(List<Widget> children, AppThemeExtension colors) {
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(Divider(height: 1, color: colors.borderSecondary));
      }
    }
    return result;
  }
}
