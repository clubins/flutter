import 'dart:convert';
import 'dart:io';

import 'package:clubins/models/insights_data.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/insights/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('summary parses the documented shape, null blocks included', () {
    final summary = InsightsSummary.fromJson(fixture('summary'));
    expect(summary.venueId, '9c3f1e42-7a6b-4d18-9f52-3e0c8b7a5d61');
    expect(summary.window, '30d');
    expect(summary.from, DateTime.utc(2026, 9, 30, 17, 6));
    expect(summary.to, DateTime.utc(2026, 10, 30, 17, 6));

    final main = summary.decibelSensors[0];
    expect(main.readings, 831924);
    expect(main.peak?.dba, 77.2);
    expect(main.peak?.time, DateTime.utc(2026, 10, 4, 3, 6, 12));
    expect(main.active?.meanDba, 52.4);
    expect(main.active?.minutes, 5417.5);
    expect(main.active?.floorDba, 15.5);
    expect(main.active?.thresholdDba, 23.5);
    expect(main.quiet?.meanDba, 15.5);
    expect(main.quiet?.minutes, 31582.5);
    expect(main.thresholds?.above85Minutes, 0.0);
    expect(main.thresholds?.above90Minutes, 0.0);
    expect(main.thresholds?.above95Minutes, 0.0);
    expect(main.bassGap?.medianDb, 5.5);
    expect(main.bassGap?.p90Db, 13.2);
    expect(main.coverage?.firstReading, DateTime.utc(2026, 9, 30, 17, 6, 1));
    expect(main.coverage?.lastReading, DateTime.utc(2026, 10, 30, 17, 5, 59));
    expect(main.coverage?.capturePct, 99.7);
    expect(main.coverage?.longestGapMinutes, 29310.0);

    // Honest empty: zero readings parse as nulls, never as zeros.
    final dark = summary.decibelSensors[1];
    expect(dark.readings, 0);
    expect(dark.peak, isNull);
    expect(dark.active, isNull);
    expect(dark.quiet, isNull);
    expect(dark.thresholds, isNull);
    expect(dark.bassGap, isNull);
    expect(dark.coverage, isNull);

    final pax = summary.paxSensors.single;
    expect(pax.readings, 0);
    expect(pax.maxOccupancy, isNull);
    expect(pax.venueHours, isNull);
    expect(pax.coverage, isNull);

    expect(summary.weatherSensors, isEmpty);

    expect(summary.health, hasLength(2));
    expect(summary.health[0].lastSeen, DateTime.utc(2026, 10, 30, 17, 5, 59));
    expect(summary.health[0].staleMinutes, 0.3);
    expect(summary.health[0].medianIntervalS, 1.0);
    expect(summary.health[0].capturePct, 99.7);
    final darkHealth = summary.health[1];
    expect(darkHealth.lastSeen, isNull);
    expect(darkHealth.staleMinutes, isNull);
    expect(darkHealth.medianIntervalS, isNull);
    expect(darkHealth.capturePct, isNull);

    expect(summary.caveats, hasLength(2));
    expect(summary.caveats.first, contains('488.5 h'));
  });

  test('daily parses rows with a 48 h gap and an inactive day', () {
    final daily = InsightsDaily.fromJson(fixture('daily'));
    expect(daily.days, hasLength(3));

    final busy = daily.days[0];
    expect(busy.dateLocal, '2026-10-03');
    expect(busy.readings, 83192);
    expect(busy.active?.meanDba, 55.6);
    expect(busy.active?.minutes, 720.0);
    expect(busy.active?.floorDba, isNull);
    expect(busy.quiet?.minutes, 720.0);
    expect(busy.peak?.dba, 77.2);
    expect(busy.thresholds.above85Minutes, 0.0);
    expect(busy.coverage.capturePct, 100.0);
    expect(busy.coverage.longestGapMinutes, 0.0);

    // The 48 h ingestion hole shows as a coverage gap, not as smooth data.
    final gap = daily.days[1];
    expect(gap.dateLocal, '2026-10-07');
    expect(gap.coverage.longestGapMinutes, 2880.0);
    expect(gap.coverage.capturePct, 63.5);

    final quiet = daily.days[2];
    expect(quiet.active, isNull);
    expect(quiet.quiet?.meanDba, 15.7);
  });

  test('hourly parses the split and per-hour rows', () {
    final hourly = InsightsHourly.fromJson(fixture('hourly'));
    expect(hourly.split, InsightsSplit.all);
    expect(hourly.hours, hasLength(3));

    final night = hourly.hours[1];
    expect(night.hourLocal, 3);
    expect(night.readings, 89501);
    expect(night.meanDba, 49.8);
    expect(night.p90Dba, 57.2);
    expect(night.maxDba, 77.2);
    expect(night.pctActive, 88.1);
    expect(night.medianBassGapDb, 12.7);
    expect(night.minutesAbove85, 0.0);
    expect(night.minutesAbove90, 0.0);
    expect(night.minutesAbove95, 0.0);

    // A bucket without paired A/C readings parses as an honest null.
    expect(hourly.hours[2].medianBassGapDb, isNull);
  });

  test('nights parse ranked rows with weekday labels', () {
    final nights = InsightsNights.fromJson(fixture('nights'));
    expect(nights.nights, hasLength(3));

    final top = nights.nights.first;
    expect(top.nightOf, '2026-10-03');
    expect(top.weekday, 'Sat');
    expect(top.activeMinutes, 720.0);
    expect(top.activeMeanDba, 55.6);
    expect(top.peakDba, 77.2);
    expect(top.minutesAbove85, 0.0);

    expect(nights.nights[1].activeMinutes, 172.6);
    expect(nights.nights[2].peakDba, 65.3);
  });
}
