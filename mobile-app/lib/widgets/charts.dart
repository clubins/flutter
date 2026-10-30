import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:intl/intl.dart';

import 'chart_style.dart';

import '../models/exchange_rate.dart';
import '../models/weather_data.dart';

class TemperatureChart extends StatelessWidget {
  const TemperatureChart({super.key, required this.data});
  final List<HourlyWeather> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No temperature data for this range.'));
    }
    final color = Theme.of(context).colorScheme.chart1;
    return LineChart(
      LineChartData(
        lineTouchData: chartLineTouch(context),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        gridData: chartGrid(context),
        titlesData: _titles(
          context,
          data.length,
          (index) => DateFormat('MMM d\nHH:mm').format(data[index].time),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].temperature),
            ],
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}

class RainChart extends StatelessWidget {
  const RainChart({super.key, required this.data});
  final List<HourlyWeather> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No rain data for this range.'));
    }
    final color = Theme.of(context).colorScheme.chart2;
    final maxY = data.fold<double>(
      1,
      (max, item) => item.rain > max ? item.rain : max,
    );
    return BarChart(
      BarChartData(
        barTouchData: chartBarTouch(context),
        maxY: maxY * 1.25,
        gridData: chartGrid(context),
        titlesData: _titles(
          context,
          data.length,
          (index) => DateFormat('MMM d\nHH:mm').format(data[index].time),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].rain,
                  color: color,
                  width: data.length > 72 ? 3 : 7,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ExchangeRateChart extends StatelessWidget {
  const ExchangeRateChart({super.key, required this.data});
  final List<ExchangeRate> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No exchange-rate data for this range.'));
    }
    final color = Theme.of(context).colorScheme.chart3;
    final min = data.map((e) => e.rate).reduce((a, b) => a < b ? a : b);
    final max = data.map((e) => e.rate).reduce((a, b) => a > b ? a : b);
    final padding = ((max - min) * .15).clamp(.001, double.infinity);
    return LineChart(
      LineChartData(
        lineTouchData: chartLineTouch(context),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: min - padding,
        maxY: max + padding,
        gridData: chartGrid(context),
        titlesData: _titles(
          context,
          data.length,
          (index) => '${data[index].date.month}/${data[index].date.day}',
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].rate),
            ],
            color: color,
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

FlTitlesData _titles(
  BuildContext context,
  int count,
  String Function(int) label,
) {
  final interval = count <= 8 ? 1 : (count / 6).ceil();
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
        interval: interval.toDouble(),
        getTitlesWidget: (value, meta) {
          final index = value.round();
          if (index < 0 || index >= count || index % interval != 0) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: SizedBox(
              width: 54,
              child: Text(
                label(index),
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
