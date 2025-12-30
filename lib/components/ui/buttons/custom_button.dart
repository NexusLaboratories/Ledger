import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';

enum ButtonVariant { primary, secondary, destructive, ghost }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDisabled = onPressed == null || loading;

    final padding = switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      ButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      ButtonSize.large => const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 16,
      ),
    };

    final fontSize = switch (size) {
      ButtonSize.small => 13.0,
      ButtonSize.medium => 14.0,
      ButtonSize.large => 16.0,
    };

    final (bgColor, fgColor, borderColor) = switch (variant) {
      ButtonVariant.primary => (
        colors.positive,
        Colors.white,
        Colors.transparent,
      ),
      ButtonVariant.secondary => (
        colors.grey200,
        colors.textPrimary,
        colors.borderPrimary,
      ),
      ButtonVariant.destructive => (
        colors.negative,
        Colors.white,
        Colors.transparent,
      ),
      ButtonVariant.ghost => (
        Colors.transparent,
        colors.textPrimary,
        Colors.transparent,
      ),
    };

    Widget buttonChild = loading
        ? SizedBox(
            height: fontSize,
            width: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fgColor),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: padding,
          elevation: variant == ButtonVariant.primary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != Colors.transparent
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}
