import 'package:flutter/material.dart';
import 'package:ledger/presets/theme.dart';

/// A test wrapper that provides the app's theme with extensions.
class TestApp extends StatelessWidget {
  final Widget? home;
  final Widget? child;

  const TestApp({super.key, this.home, this.child}) : assert(home != null || child != null);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      home: home ?? child,
    );
  }
}