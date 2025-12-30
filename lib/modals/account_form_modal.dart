import 'package:flutter/material.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/constants/tag_icons.dart';

class AccountFormModal extends StatefulWidget {
  final Account? account;
  final AbstractAccountService? accountService;
  const AccountFormModal({super.key, this.account, this.accountService});

  @override
  State<AccountFormModal> createState() => _AccountFormModalState();
}

class _AccountFormModalState extends State<AccountFormModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final AbstractAccountService _accountService =
      widget.accountService ?? AccountService();
  late final bool _isEditMode = widget.account != null;

  String? _nameError;
  String? _selectedIconId;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _descriptionController.text = widget.account!.description ?? '';
      _selectedIconId = widget.account!.iconId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _nameError = null;
    });

    final value = _nameController.text;

    if (value.isEmpty) {
      setState(() => _nameError = 'Please enter account name');
      return;
    }

    if (RegExp(r'\d').hasMatch(value)) {
      setState(() => _nameError = 'Account name cannot contain numbers');
      return;
    }

    List<Account?> accounts = await _accountService.fetchAccounts();
    if (accounts.any(
      (account) =>
          account!.name.toLowerCase() == value.toLowerCase() &&
          account.id != widget.account?.id,
    )) {
      setState(() => _nameError = 'An account with this name already exists');
      return;
    }

    final defaultCurrency = await UserPreferenceService.getDefaultCurrency();

    final accountData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'currency': defaultCurrency,
      'iconId': _selectedIconId,
    };
    if (_isEditMode) accountData['id'] = widget.account!.id;

    if (mounted) Navigator.pop(context, accountData);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditMode ? 'Edit Account' : 'Create Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // Close icon removed as per design (Cancel button below suffices)
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            // Icon picker
            InkWell(
              onTap: _showIconPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedIconId != null
                            ? (TagIcons.getIconById(_selectedIconId!) ??
                                      TagIcons.defaultIcon)
                                  .icon
                            : Icons.account_balance_wallet,
                        color: const Color(0xFF43A047),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedIconId != null
                            ? (TagIcons.getIconById(_selectedIconId!)?.name ??
                                  'Select Icon')
                            : 'Select Icon (Optional)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Currency selection removed. Accounts use the app's default currency.
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    variant: ButtonVariant.destructive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: _isEditMode ? 'Update' : 'Create',
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: TagIcons.allIcons.length,
            itemBuilder: (context, index) {
              final tagIcon = TagIcons.allIcons[index];
              final isSelected = _selectedIconId == tagIcon.id;
              return InkWell(
                onTap: () {
                  setState(() => _selectedIconId = tagIcon.id);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF43A047)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? const Color(0xFF43A047).withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tagIcon.icon,
                        size: 28,
                        color: isSelected
                            ? const Color(0xFF43A047)
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tagIcon.name,
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected
                              ? const Color(0xFF43A047)
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedIconId = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
