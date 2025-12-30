import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? content;
  final List<Widget>? actions;
  final Widget? child;

  const CustomDialog({
    super.key,
    required this.title,
    this.content,
    this.actions,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: child ?? (content != null ? Text(content!) : null),
      actions:
          actions ??
          [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
    );
  }
}
