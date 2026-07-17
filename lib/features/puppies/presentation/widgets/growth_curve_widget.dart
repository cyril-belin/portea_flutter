import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Growth curve for a puppy: a line chart of weight (g) over time. The
/// weighings are expected already sorted by ascending date (the server returns
/// them so). When the puppy has fewer than two weighings the widget shows a
/// placeholder — a curve needs at least two points.
class GrowthCurveWidget extends StatelessWidget {
  const GrowthCurveWidget({super.key, required this.weighings});

  final List<WeighingEntry> weighings;

  @override
  Widget build(BuildContext context) {
    if (weighings.length < 2) {
      return _emptyState(context);
    }

    final spots = [
      for (var i = 0; i < weighings.length; i++)
        FlSpot(i.toDouble(), weighings[i].weightGrams),
    ];
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Pad the vertical range so the line never hugs the border.
    final padding = (maxY - minY) * 0.1;
    final bottom = (minY - padding).floorToDouble();
    final top = (maxY + padding).ceilToDouble();

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: bottom,
          maxY: top,
          minX: 0,
          maxX: (weighings.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: _bottomTitle,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: _leftTitle,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }

  /// Left axis: weight in grams, rounded.
  Widget _leftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        '${value.round()} g',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  /// Bottom axis: date of the weighing at this index (dd/MM), one per point.
  Widget _bottomTitle(double value, TitleMeta meta) {
    final index = value.round();
    if (index < 0 || index >= weighings.length) {
      return const SizedBox.shrink();
    }
    final d = weighings[index].weighedAt;
    return SideTitleWidget(
      meta: meta,
      child: Text(
        '${d.day}/${d.month}',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  /// Placeholder kept in the spirit of the previous design — shown when there
  /// is nothing to plot yet (no weighing, or just one).
  Widget _emptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDark.withValues(alpha: 0.2)
            : AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          weighings.isEmpty
              ? 'Aucune pesée enregistrée'
              : 'Ajoutez une 2ᵉ pesée pour voir la courbe',
          style: AppTextStyles.captionLabel.copyWith(
            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
