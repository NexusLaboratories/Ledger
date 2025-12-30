import 'package:flutter/material.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/utilities/utilities.dart';

/// A reusable dialog for adding or editing transaction items
class ItemFormDialog extends StatefulWidget {
  final TransactionItem? existingItem;

  const ItemFormDialog({super.key, this.existingItem});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? '',
    );
    _qtyController = TextEditingController(
      text: widget.existingItem?.quantity?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingItem?.price?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _inlineError = 'Name is required';
      });
      return;
    }

    final qty = double.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    final id = widget.existingItem?.id ?? Utilities.generateUuid();
    final item = TransactionItem(
      id: id,
      transactionId: widget.existingItem?.transactionId ?? '',
      name: name,
      quantity: qty,
      price: price,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem == null ? 'Add item' : 'Edit item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _inlineError,
            ),
            onChanged: (_) {
              if (_inlineError != null) {
                setState(() {
                  _inlineError = null;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _handleSave, child: const Text('Save')),
      ],
    );
  }
}
