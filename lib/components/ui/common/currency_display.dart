import 'package:flutter/material.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';

/// Simple currency display which uses the user's selected default currency.
/// Note: multi-currency conversion has been removed; amounts are expected
/// to be stored in the app's selected currency.
class CurrencyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const CurrencyDisplay({super.key, required this.amount, this.style});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserPreferenceService.getDefaultCurrency(),
      builder: (context, snapshot) {
        final currency = snapshot.data ?? 'INR';
        return Text(CurrencyFormatter.format(amount, currency), style: style);
      },
    );
  }
}
