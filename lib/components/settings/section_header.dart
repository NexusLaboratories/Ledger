import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';

enum SectionHeaderStyle { accent, subtle }

class SectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final VoidCallback? onViewAll;
  final EdgeInsets? padding;
  final SectionHeaderStyle style;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.onViewAll,
    this.padding,
    this.style = SectionHeaderStyle.accent,
    this.color,
  });

  /// Factory for settings-style headers (replaces SettingsSectionHeader)
  factory SectionHeader.settings({
    required String title,
    Color? color,
    EdgeInsets? padding,
  }) {
    return SectionHeader(
      title: title,
      style: SectionHeaderStyle.subtle,
      color: color,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (style == SectionHeaderStyle.subtle) {
      // Settings-style header
      return Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: color ?? colors.textMuted,
          ),
        ),
      );
    }

    // Accent-style header (original)
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (color ?? colors.positive).withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: color ?? colors.positive,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.grey200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: TextStyle(fontSize: 13, color: color ?? colors.positive),
              ),
            ),
        ],
      ),
    );
  }
}
