import 'package:flutter/material.dart';
import 'package:ledger/presets/theme.dart';

/// Utility functions for common dialog patterns
class DialogUtils {
  /// Shows a confirmation dialog with customizable title, content, and actions
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Shows a loading dialog that cannot be dismissed
  static void showLoadingDialog({
    required BuildContext context,
    String message = 'Loading...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a success SnackBar
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Shows an error SnackBar
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CustomColors.negative,
        duration: duration,
      ),
    );
  }

  /// Shows a warning SnackBar
  static void showWarningSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  /// Shows a dialog with multiple choice options
  static Future<T?> showChoiceDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<DialogChoice<T>> choices,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: choices.map((choice) {
          return choice.isDestructive
              ? TextButton(
                  onPressed: () => Navigator.pop(context, choice.value),
                  child: Text(
                    choice.label,
                    style: TextStyle(color: CustomColors.red400),
                  ),
                )
              : choice.isPrimary
                  ? ElevatedButton(
                      onPressed: () => Navigator.pop(context, choice.value),
                      child: Text(choice.label),
                    )
                  : TextButton(
                      onPressed: () => Navigator.pop(context, choice.value),
                      child: Text(choice.label),
                    );
        }).toList(),
      ),
    );
  }

  /// Shows a success dialog with an icon and message
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

/// Represents a choice option for choice dialogs
class DialogChoice<T> {
  final String label;
  final T? value;
  final bool isPrimary;
  final bool isDestructive;

  const DialogChoice({
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}