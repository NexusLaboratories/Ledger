import 'package:flutter/material.dart';
import 'package:ledger/services/report_service.dart';
import 'package:ledger/models/report_options.dart';
import 'package:ledger/components/reports/report_customization_modal.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:share_plus/share_plus.dart';

class ExportSpreadsheetDialog extends StatefulWidget {
  final ReportOptions initialOptions;
  const ExportSpreadsheetDialog({super.key, required this.initialOptions});

  @override
  State<ExportSpreadsheetDialog> createState() =>
      _ExportSpreadsheetDialogState();
}

class _ExportSpreadsheetDialogState extends State<ExportSpreadsheetDialog> {
  SheetLayout _layout = SheetLayout.byAccount;
  String _txnType = 'both';
  late ReportOptions _opts;
  bool _loading = false;
  final ReportService _service = ReportService();

  @override
  void initState() {
    super.initState();
    _opts = widget.initialOptions;
  }

  Future<void> _customizeFilters() async {
    final result = await showDialog<ReportOptions?>(
      context: context,
      builder: (context) => ReportCustomizationModal(initial: _opts),
    );
    if (result != null) {
      setState(() {
        _opts = result;
      });
    }
  }

  Future<void> _generateAndShare() async {
    setState(() => _loading = true);
    try {
      final path = await _service.generateTransactionsXlsx(
        _opts,
        layout: _layout,
        transactionTypeFilter: _txnType,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'Ledger transactions export',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export to Spreadsheet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sheet organisation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SheetLayout>(
                initialValue: _layout,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SheetLayout.single,
                    child: Text('Single sheet (All transactions)'),
                  ),
                  DropdownMenuItem(
                    value: SheetLayout.byAccount,
                    child: Text('Sheet per Account'),
                  ),
                  DropdownMenuItem(
                    value: SheetLayout.byCategory,
                    child: Text('Sheet per Category'),
                  ),
                  DropdownMenuItem(
                    value: SheetLayout.byMonth,
                    child: Text('Sheet per Month'),
                  ),
                ],
                onChanged: (v) => setState(() => _layout = v!),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transaction Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _txnType,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                ],
                onChanged: (v) => setState(() => _txnType = v!),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Customize Filters',
                fullWidth: true,
                onPressed: _loading ? null : _customizeFilters,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Create',
                      onPressed: _loading ? null : _generateAndShare,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
