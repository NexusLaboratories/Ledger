import 'package:flutter/material.dart';
import 'package:ledger/services/error_handler_service.dart';

/// A widget that displays errors in a user-friendly way
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
                tooltip: 'Retry',
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A wrapper widget that handles async operations with error handling
class AsyncOperationBuilder<T> extends StatefulWidget {
  final Future<T> Function() operation;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final String operationContext;

  const AsyncOperationBuilder({
    super.key,
    required this.operation,
    required this.builder,
    required this.operationContext,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<AsyncOperationBuilder<T>> createState() =>
      _AsyncOperationBuilderState<T>();
}

class _AsyncOperationBuilderState<T> extends State<AsyncOperationBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.operation();
  }

  void _retry() {
    setState(() {
      _future = widget.operation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final errorMessage = ErrorHandlerService.getErrorMessage(
            snapshot.error,
          );
          return widget.errorBuilder?.call(context, snapshot.error) ??
              ErrorDisplay(message: errorMessage, onRetry: _retry);
        }

        if (!snapshot.hasData) {
          return const ErrorDisplay(message: 'No data available');
        }

        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}

/// Extension on BuildContext to easily show error messages
extension ErrorHandlingContext on BuildContext {
  void showError(String message, {SnackBarAction? action}) {
    ErrorHandlerService.showErrorSnackBar(this, message, action: action);
  }

  void showSuccess(String message) {
    ErrorHandlerService.showSuccessSnackBar(this, message);
  }

  Future<void> showErrorDialog({
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
  }) {
    return ErrorHandlerService.showErrorDialog(
      this,
      title: title,
      message: message,
      details: details,
      onRetry: onRetry,
    );
  }
}
