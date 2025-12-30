import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';
import 'package:ledger/components/ui/common/icon_container.dart';

enum InfoCardVariant { info, success, warning, error }

/// A versatile card for displaying messages with icons, colors, and optional actions.
/// Use this for both persistent info cards and dismissible banners.
class InfoCard extends StatelessWidget {
  final String message;
  final InfoCardVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onDismiss;
  final bool compact;

  const InfoCard({
    super.key,
    required this.message,
    this.variant = InfoCardVariant.info,
    this.icon,
    this.onTap,
    this.actionLabel,
    this.onDismiss,
    this.compact = false,
  });

  /// Factory constructor for dismissible banners (replaces WarningBanner)
  factory InfoCard.banner({
    required String message,
    InfoCardVariant variant = InfoCardVariant.warning,
    IconData? icon,
    VoidCallback? onDismiss,
  }) {
    return InfoCard(
      message: message,
      variant: variant,
      icon: icon,
      onDismiss: onDismiss,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final (displayIcon, color) = switch (variant) {
      InfoCardVariant.info => (icon ?? Icons.info_outline, colors.positive),
      InfoCardVariant.success => (
        icon ?? Icons.check_circle_outline,
        colors.positive,
      ),
      InfoCardVariant.warning => (
        icon ?? Icons.warning_amber_rounded,
        colors.warning,
      ),
      InfoCardVariant.error => (icon ?? Icons.error_outline, colors.negative),
    };

    final content = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.all(16),
      child: Row(
        children: [
          IconContainer(
            icon: displayIcon,
            color: color,
            iconSize: 24,
            padding: 8,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ] else if (actionLabel != null && onTap != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel!, style: TextStyle(color: color)),
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        border: Border.all(color: color.withAlpha(51)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: onTap != null && actionLabel == null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: content,
            )
          : content,
    );
  }
}
