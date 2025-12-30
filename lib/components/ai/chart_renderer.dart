import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ledger/presets/theme.dart';
import 'package:intl/intl.dart';

class ChartRenderer extends StatelessWidget {
  final String chartType;
  final Map<String, dynamic> data;

  const ChartRenderer({super.key, required this.chartType, required this.data});

  String _getMonthLabel(String monthStr) {
    try {
      final parts = monthStr.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        final date = DateTime(int.parse(year), month);
        return DateFormat('MMM').format(date);
      }
    } catch (e) {
      // Fallback to original
    }
    return monthStr;
  }

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case 'pie':
        return _buildPieChart(context);
      case 'bar':
        return _buildBarChart(context);
      case 'line':
        return _buildLineChart(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPieChart(BuildContext context) {
    final categories = (data['data'] as List?) ?? [];
    if (categories.isEmpty) return const SizedBox.shrink();

    final colors = [
      CustomColors.primary,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PieChart(
        PieChartData(
          sections: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value as Map<String, dynamic>;
            final amount = (cat['amount'] as num?)?.toDouble() ?? 0;
            final percentage = (cat['percentage'] as num?)?.toDouble() ?? 0;

            return PieChartSectionData(
              value: amount,
              title: (percentage > 0 && percentage <= 100)
                  ? '${percentage.toStringAsFixed(0)}%'
                  : '',
              color: colors[index % colors.length],
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final monthlyData = (data['data'] as List?) ?? [];
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              monthlyData.fold<double>(0, (max, item) {
                final expense = (item['expense'] as num?)?.toDouble() ?? 0;
                return expense > max ? expense : max;
              }) *
              1.2,
          barGroups: monthlyData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final expense = (item['expense'] as num?)?.toDouble() ?? 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: expense,
                  color: CustomColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          minY: 0,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < monthlyData.length) {
                    final monthStr =
                        monthlyData[value.toInt()]['month'] as String?;
                    if (monthStr != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _getMonthLabel(monthStr),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final monthlyData = (data['data'] as List?) ?? [];
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    final spots = monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final expense = (item['expense'] as num?)?.toDouble() ?? 0;
      return FlSpot(index.toDouble(), expense);
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: CustomColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: CustomColors.primary.withAlpha(51),
              ),
            ),
          ],
          minY: 0,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < monthlyData.length) {
                    final monthStr =
                        monthlyData[value.toInt()]['month'] as String?;
                    if (monthStr != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _getMonthLabel(monthStr),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }
}
