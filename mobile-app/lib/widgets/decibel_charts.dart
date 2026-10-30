import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:intl/intl.dart';

import 'chart_style.dart';

import '../models/decibel_data.dart';

/// Line chart of dB(A) readings for one or more sensors.
class DecibelChart extends StatelessWidget {
  const DecibelChart({super.key, required this.series, this.height = 280});

  final List<DecibelSensorHistory> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.chart1,
      Theme.of(context).colorScheme.chart2,
      Theme.of(context).colorScheme.chart3,
    ];
    final orderedSeries = [
      for (final s in series)
        DecibelSensorHistory(
          sensor: s.sensor,
          readings: [...s.readings]..sort((a, b) => a.time.compareTo(b.time)),
        ),
    ];
    final allReadings = [for (final s in orderedSeries) ...s.readings];
    if (allReadings.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No sound readings for this range.')),
      );
    }

    final start = allReadings
        .map((reading) => reading.time)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final end = allReadings
        .map((reading) => reading.time)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final maxX =
        end.difference(start).inMilliseconds / Duration.millisecondsPerMinute;
    final allValues = allReadings.map((reading) => reading.dba);
    final min = allValues.reduce((a, b) => a < b ? a : b);
    final max = allValues.reduce((a, b) => a > b ? a : b);
    final padding = ((max - min) * .15).clamp(1.0, double.infinity);
    String label(double minutes) {
      final time = start
          .add(Duration(milliseconds: (minutes * 60000).round()))
          .toLocal();
      return DateFormat('MMM d\nHH:mm').format(time);
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          lineTouchData: chartLineTouch(context),
          minX: 0,
          maxX: maxX == 0 ? 1 : maxX,
          minY: (min - padding).clamp(0, double.infinity),
          maxY: max + padding,
          gridData: chartGrid(context),
          titlesData: _titles(context, maxX == 0 ? 1 : maxX, label),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            for (var i = 0; i < orderedSeries.length; i++)
              LineChartBarData(
                spots: [
                  for (final reading in orderedSeries[i].readings)
                    FlSpot(
                      reading.time.difference(start).inMilliseconds /
                          Duration.millisecondsPerMinute,
                      reading.dba,
                    ),
                ],
                color: colors[i % colors.length],
                barWidth: 2,
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}

FlTitlesData _titles(
  BuildContext context,
  double maxX,
  String Function(double) label,
) {
  final interval = maxX / 6;
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(meta.formattedValue, style: chartLabelStyle(context)),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 46,
        interval: interval,
        getTitlesWidget: (value, meta) {
          return SideTitleWidget(
            meta: meta,
            child: SizedBox(
              width: 54,
              child: Text(
                label(value),
                textAlign: TextAlign.center,
                style: chartLabelStyle(context),
              ),
            ),
          );
        },
      ),
    ),
  );
}
