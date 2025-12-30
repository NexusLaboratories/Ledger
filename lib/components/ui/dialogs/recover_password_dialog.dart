import 'package:flutter/material.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/theme.dart';

const int minPasswordLength = 4;

/// Dialog for recovering database password
class RecoverPasswordDialog extends StatefulWidget {
  const RecoverPasswordDialog({super.key});

  @override
  State<RecoverPasswordDialog> createState() => _RecoverPasswordDialogState();
}

class _RecoverPasswordDialogState extends State<RecoverPasswordDialog> {
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    setState(() => _errorMessage = null);

    // Validate password
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Password cannot be empty';
      });
      return;
    }

    if (_passwordController.text.trim().length < minPasswordLength) {
      setState(() {
        _errorMessage =
            'Password must be at least $minPasswordLength characters';
      });
      return;
    }

    try {
      // Restore the password to secure storage
      await UserPreferenceService.setDBPassword(
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error restoring password: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recover Database Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Re-enter your database password to restore access. The password cache was lost, but your encrypted data is safe. Enter the password you remember.',
                      style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Database Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                helperText: 'Enter the password you remember',
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: CustomColors.red400),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
          onPressed: _handleRecover,
          child: const Text('Recover Password'),
        ),
      ],
    );
  }
}
