import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';

enum LoadingSize { small, medium, large }

class LoadingIndicator extends StatelessWidget {
  final EdgeInsets? padding;
  final String? message;
  final LoadingSize size;

  const LoadingIndicator({
    super.key,
    this.padding,
    this.message,
    this.size = LoadingSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final indicatorSize = switch (size) {
      LoadingSize.small => 20.0,
      LoadingSize.medium => 30.0,
      LoadingSize.large => 40.0,
    };

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: size == LoadingSize.small ? 2 : 3,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: TextStyle(color: colors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
