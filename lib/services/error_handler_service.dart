import 'package:flutter/material.dart';
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/logger_service.dart';

/// Centralized error handling service for consistent error management across the app
class ErrorHandlerService {
  /// Show a user-friendly error message in a SnackBar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Theme.of(context).colorScheme.error,
        action: action,
      ),
    );
  }

  /// Show a success message in a SnackBar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.green[700],
      ),
    );
  }

  /// Show an error dialog with detailed information
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      details,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Handle an exception and return a user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is DatabaseException) {
      return _handleDatabaseException(error);
    } else if (error is ServiceException) {
      return _handleServiceException(error);
    } else if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    } else if (error is Exception) {
      return 'An error occurred: ${error.toString()}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle database exceptions
  static String _handleDatabaseException(DatabaseException error) {
    if (error is DatabaseNotOpenException) {
      return 'Database connection error. Please restart the app.';
    } else if (error is DatabaseInitializationException) {
      return 'Failed to initialize database. Please check your settings.';
    } else if (error is PasswordNotFoundException) {
      return 'Database password not configured. Please set a password.';
    } else if (error is AccountNotFoundException) {
      return 'Account not found. It may have been deleted.';
    } else if (error is DatabaseQueryException) {
      return 'Failed to retrieve data. Please try again.';
    } else if (error is DatabaseInsertException) {
      return 'Failed to save data. Please try again.';
    } else if (error is DatabaseUpdateException) {
      return 'Failed to update data. Please try again.';
    } else if (error is DatabaseDeleteException) {
      return 'Failed to delete data. Please try again.';
    } else {
      return 'Database error: ${error.message}';
    }
  }

  /// Handle service exceptions
  static String _handleServiceException(ServiceException error) {
    if (error is ValidationException) {
      return 'Validation error: ${error.message}';
    } else if (error is NetworkException) {
      return 'Network error: ${error.message}. Please check your connection.';
    } else if (error is AuthenticationException) {
      return 'Authentication error: ${error.message}';
    } else if (error is ImportException) {
      return 'Import failed: ${error.message}';
    } else if (error is ExportException) {
      return 'Export failed: ${error.message}';
    } else if (error is FileOperationException) {
      return 'File operation failed: ${error.message}';
    } else if (error is ParseException) {
      return 'Failed to parse data: ${error.message}';
    } else if (error is BiometricException) {
      return 'Biometric authentication failed: ${error.message}';
    } else if (error is NotificationException) {
      return 'Notification error: ${error.message}';
    } else if (error is CurrencyConversionException) {
      return 'Currency conversion failed: ${error.message}';
    } else {
      return 'Service error: ${error.message}';
    }
  }

  /// Handle and log an error, then optionally show a message to the user
  static Future<void> handleError(
    dynamic error,
    StackTrace stackTrace, {
    required String context,
    BuildContext? uiContext,
    bool showSnackBar = true,
    VoidCallback? onRetry,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Log the error with context
    final logMessage =
        context +
        (additionalContext != null && additionalContext.isNotEmpty
            ? ' | Context: $additionalContext'
            : '');
    LoggerService.e(logMessage, error, stackTrace);

    // Get user-friendly message
    final message = getErrorMessage(error);

    // Show to user if context is provided
    if (uiContext != null && uiContext.mounted) {
      if (showSnackBar) {
        showErrorSnackBar(
          uiContext,
          message,
          action: onRetry != null
              ? SnackBarAction(label: 'Retry', onPressed: onRetry)
              : null,
        );
      } else {
        await showErrorDialog(
          uiContext,
          title: 'Error',
          message: message,
          details: error.toString(),
          onRetry: onRetry,
        );
      }
    }
  }

  /// Wrap a future operation with error handling
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    required String context,
    BuildContext? uiContext,
    bool showErrorToUser = true,
    T? fallbackValue,
    VoidCallback? onRetry,
    Map<String, dynamic>? additionalContext,
  }) async {
    LoggerService.i('Starting: $context');
    try {
      final result = await operation();
      LoggerService.i('Completed: $context');
      return result;
    } catch (e, stackTrace) {
      // The uiContext may become invalid if the caller's widget is disposed while
      // the operation was in progress. We still attempt to show the error, but
      // suppress the lint since `handleError` checks `uiContext?.mounted` before
      // performing UI operations.
      await handleError(
        e,
        stackTrace,
        context: context,
        uiContext: uiContext, // ignore: use_build_context_synchronously
        showSnackBar: showErrorToUser,
        onRetry: onRetry,
        additionalContext: additionalContext,
      );
      return fallbackValue;
    }
  }

  /// Wrap a synchronous operation with error handling
  static T? wrapSync<T>(
    T Function() operation, {
    required String context,
    BuildContext? uiContext,
    bool showErrorToUser = true,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      handleError(
        e,
        stackTrace,
        context: context,
        uiContext: uiContext,
        showSnackBar: showErrorToUser,
      );
      return fallbackValue;
    }
  }
}
