import 'dart:convert';
import 'dart:io';

import 'package:clubins/models/insights_data.dart';
import 'package:clubins/services/insights_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/insights/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test(
    'fetchSummary encodes the window and parses the documented shape',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(fixture('summary')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = InsightsService(
        idToken: () => 'signed-id-token',
        client: client,
      );

      final summary = await service.fetchSummary();
      expect(requests.single.url.queryParameters['window'], '30d');
      expect(summary.decibelSensors, hasLength(2));
      expect(summary.caveats, hasLength(2));

      await service.fetchSummary(window: InsightsWindow.sevenDays);
      expect(requests.last.url.queryParameters['window'], '7d');
      service.close();
    },
  );

  test('range routes encode from/to and parse their fixtures', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final name = switch (request.url.path.split('/').last) {
        'daily' => 'daily',
        'hourly' => 'hourly',
        _ => 'nights',
      };
      return http.Response(
        jsonEncode(fixture(name)),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = InsightsService(
      idToken: () => 'signed-id-token',
      client: client,
    );
    final from = DateTime.utc(2026, 9, 30, 17, 6);
    final to = DateTime.utc(2026, 10, 30, 17, 6);

    final daily = await service.fetchDaily(from: from, to: to);
    expect(requests[0].url.queryParameters['from'], '2026-09-30T17:06:00.000Z');
    expect(requests[0].url.queryParameters['to'], '2026-10-30T17:06:00.000Z');
    expect(daily.days, hasLength(3));

    final hourly = await service.fetchHourly(
      from: from,
      to: to,
      split: InsightsSplit.weekend,
    );
    expect(requests[1].url.queryParameters['split'], 'weekend');
    expect(hourly.hours, hasLength(3));

    final nights = await service.fetchNights(from: from, limit: 31);
    expect(requests[2].url.queryParameters.containsKey('to'), isFalse);
    expect(requests[2].url.queryParameters['limit'], '31');
    expect(nights.nights.first.activeMinutes, 720.0);
    service.close();
  });

  test('rejects an out-of-range nights limit before making a request', () {
    final service = InsightsService(
      idToken: () => 'signed-id-token',
      client: MockClient((request) async => http.Response('', 200)),
    );

    expect(
      () => service.fetchNights(from: DateTime.utc(2026, 10, 1), limit: 0),
      throwsArgumentError,
    );
    expect(
      () => service.fetchNights(from: DateTime.utc(2026, 10, 1), limit: 32),
      throwsArgumentError,
    );
    service.close();
  });
}
