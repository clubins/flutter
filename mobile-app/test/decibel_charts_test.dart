import 'package:clubins/models/decibel_data.dart';
import 'package:clubins/widgets/decibel_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sensor = DecibelSensor(
    sensorId: 'sensor-1',
    location: 'Main floor',
    types: ['decibel'],
  );

  testWidgets('shows an empty state when there are no readings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ShadcnApp(
        home: Scaffold(child: DecibelChart(series: [])),
      ),
    );

    expect(find.text('No sound readings for this range.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('positions readings using their timestamps', (tester) async {
    final start = DateTime.utc(2026, 1, 1, 12);
    final series = [
      DecibelSensorHistory(
        sensor: sensor,
        readings: [
          DecibelReading(time: start, dba: 60, dbc: 70),
          DecibelReading(
            time: start.add(const Duration(minutes: 90)),
            dba: 65,
            dbc: 75,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ShadcnApp(
        home: Scaffold(child: DecibelChart(series: series)),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots.map((spot) => spot.x), [0, 90]);
  });
}
