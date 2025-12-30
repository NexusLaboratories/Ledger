import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ledger/models/category_summary.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/components/ui/common/glass_container.dart';

class SpendingByCategoryWidget extends StatefulWidget {
  const SpendingByCategoryWidget({super.key});

  @override
  State<SpendingByCategoryWidget> createState() =>
      _SpendingByCategoryWidgetState();
}

class _SpendingByCategoryWidgetState extends State<SpendingByCategoryWidget> {
  final CategoryService _categoryService = CategoryService();
  List<CategorySummary> _categorySummaries = [];
  bool _isLoading = true;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currency = await UserPreferenceService.getDefaultCurrency();
      // Use 'local' as userId since that's the default in the app
      final allSummaries = await _categoryService.getCategorySummaries('local');
      final allCategories = await _categoryService.fetchCategoriesForUser(
        'local',
      );

      // Filter to only include top-level categories (categories without a parent)
      final parentCategoryIds = allCategories
          .where((cat) => cat.parentCategoryId == null)
          .map((cat) => cat.id)
          .toSet();

      _categorySummaries = allSummaries
          .where((summary) => parentCategoryIds.contains(summary.id))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_categorySummaries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No spending data',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getNiceMaxAmount(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _categorySummaries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _categorySummaries[value.toInt()].name,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatCompact(value, _currency),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getNiceMaxAmount() / 5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxAmount() {
    if (_categorySummaries.isEmpty) return 100;
    return _categorySummaries
        .map((s) => s.totalAmount)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Returns a rounded "nice" value suitable for chart maxY and grid lines.
  /// Rounds up to a friendly interval (1, 2, 5 * 10^n) so bars don't touch the top.
  double _getNiceMaxAmount() {
    final m = _getMaxAmount();
    if (m <= 0) return 100;

    final magnitude = pow(10, (log(m) / ln10).floor()).toDouble();
    final normalized = m / magnitude;

    double roundedNormalized;
    if (normalized <= 1) {
      roundedNormalized = 1;
    } else if (normalized <= 2) {
      roundedNormalized = 2;
    } else if (normalized <= 5) {
      roundedNormalized = 5;
    } else {
      roundedNormalized = 10;
    }

    return roundedNormalized * magnitude * 1.1; // small headroom
  }

  List<BarChartGroupData> _buildBarGroups() {
    final colors = CustomColors.categoryPalette;

    return _categorySummaries.asMap().entries.map((entry) {
      final index = entry.key;
      final summary = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: summary.totalAmount,
            color: colors[index % colors.length],
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }
}
