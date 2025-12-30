import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showCard;
  final EdgeInsets? padding;
  final double? iconSize;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.showCard = true,
    this.padding,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: iconSize ?? 48,
            color: iconColor ?? colors.iconSecondary,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );

    if (!showCard) {
      return Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(32),
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: content,
    );
  }
}

/// Simple empty state for lists (compact, no card)
class SimpleEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final EdgeInsets? padding;

  const SimpleEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: colors.iconSecondary),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
