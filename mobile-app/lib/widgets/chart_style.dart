import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

FlGridData chartGrid(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) =>
      FlLine(color: Theme.of(context).colorScheme.border, strokeWidth: 1),
);

TextStyle chartLabelStyle(BuildContext context) => Theme.of(context)
    .typography
    .xSmall
    .copyWith(color: Theme.of(context).colorScheme.mutedForeground);

LineTouchData chartLineTouch(BuildContext context) => LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (_) => Theme.of(context).colorScheme.popover,
    tooltipBorder: BorderSide(color: Theme.of(context).colorScheme.border),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItems: (spots) => [
      for (final spot in spots)
        LineTooltipItem(
          spot.y.toString(),
          TextStyle(
            color:
                spot.bar.color ??
                Theme.of(context).colorScheme.popoverForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  ),
);

BarTouchData chartBarTouch(BuildContext context) => BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => Theme.of(context).colorScheme.popover,
    tooltipBorder: BorderSide(color: Theme.of(context).colorScheme.border),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
      rod.toY.toString(),
      TextStyle(color: Theme.of(context).colorScheme.popoverForeground),
    ),
  ),
);
