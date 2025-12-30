import 'package:flutter/material.dart';
import 'package:ledger/components/ui/common/icon_container.dart';

class TransactionDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const TransactionDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconContainer(
          icon: icon,
          color: Theme.of(context).primaryColor,
          iconSize: 20,
          padding: 8,
          borderRadius: 8,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
