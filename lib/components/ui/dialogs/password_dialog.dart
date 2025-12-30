import 'package:flutter/material.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/theme.dart';

const int minPasswordLength = 4;

/// Dialog for setting/changing database password
class PasswordDialog extends StatefulWidget {
  final bool hasPassword;

  const PasswordDialog({super.key, required this.hasPassword});

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRemovePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Password'),
        content: const Text(
          'Are you sure you want to remove the database password?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: CustomColors.red400),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentPassword = _currentPasswordController.text.trim();
        final storedPassword = await UserPreferenceService.getDBPassword();

        if (currentPassword != storedPassword) {
          setState(() {
            _errorMessage = 'Current password is incorrect';
          });
          return;
        }

        await UserPreferenceService.clearDBPassword();
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error removing password: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleSavePassword() async {
    setState(() => _errorMessage = null);

    // Validate current password if exists
    if (widget.hasPassword) {
      final currentPassword = _currentPasswordController.text.trim();
      final storedPassword = await UserPreferenceService.getDBPassword();

      if (currentPassword != storedPassword) {
        setState(() {
          _errorMessage = 'Current password is incorrect';
        });
        return;
      }
    }

    // Validate new password
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Password cannot be empty';
      });
      return;
    }

    if (newPassword.length < minPasswordLength) {
      setState(() {
        _errorMessage =
            'Password must be at least $minPasswordLength characters';
      });
      return;
    }

    if (newPassword != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    // Save password
    try {
      await UserPreferenceService.setDBPassword(password: newPassword);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving password: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasPassword ? 'Change Password' : 'Set Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.hasPassword) ...[
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock),
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
        if (widget.hasPassword)
          TextButton(
            onPressed: _handleRemovePassword,
            child: const Text(
              'Remove',
              style: TextStyle(color: CustomColors.red400),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSavePassword,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
