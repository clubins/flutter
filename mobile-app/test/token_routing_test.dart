import 'package:clubins/services/clubins_api_service.dart';
import 'package:clubins/services/frankfurter_service.dart';
import 'package:clubins/services/insights_service.dart';
import 'package:clubins/services/open_meteo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'sends the ID token only to the Clubins API and rejects redirects',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://elsewhere.test/'},
        );
      });
      final service = ClubinsApiService(
        idToken: () => 'signed-id-token',
        client: client,
      );

      await expectLater(service.fetchSensors(), throwsException);
      expect(requests, hasLength(1));
      expect(requests.single.url.host, 'api.clubins.de');
      expect(
        requests.single.headers['Authorization'],
        'Bearer signed-id-token',
      );
      expect(requests.single.followRedirects, isFalse);
      service.close();
    },
  );

  test('does not make Clubins API calls without a current token', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('', 200);
    });
    final service = ClubinsApiService(idToken: () => null, client: client);

    await expectLater(service.fetchSensors(), throwsStateError);
    expect(called, isFalse);
    service.close();
  });

  test(
    'insights requests carry the token only to the Clubins API and reject redirects',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://elsewhere.test/'},
        );
      });
      final service = InsightsService(
        idToken: () => 'signed-id-token',
        client: client,
      );
      final from = DateTime.utc(2026, 10, 1);

      await expectLater(service.fetchSummary(), throwsException);
      await expectLater(service.fetchDaily(from: from), throwsException);
      await expectLater(service.fetchHourly(from: from), throwsException);
      await expectLater(service.fetchNights(from: from), throwsException);

      final venuePath = '/app/v0/venues/${ClubinsApiService.venueId}/insights';
      expect(requests, hasLength(4));
      expect(requests.map((request) => request.url.path), [
        '$venuePath/summary',
        '$venuePath/daily',
        '$venuePath/hourly',
        '$venuePath/nights',
      ]);
      expect(
        requests.every(
          (request) =>
              request.url.scheme == 'https' &&
              request.url.host == 'api.clubins.de',
        ),
        isTrue,
      );
      expect(
        requests.every(
          (request) =>
              request.headers['Authorization'] == 'Bearer signed-id-token',
        ),
        isTrue,
      );
      expect(
        requests.every((request) => request.followRedirects == false),
        isTrue,
      );
      service.close();
    },
  );

  test('does not make insights calls without a current token', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('', 200);
    });
    final service = InsightsService(idToken: () => null, client: client);
    final from = DateTime.utc(2026, 10, 1);

    await expectLater(service.fetchSummary(), throwsStateError);
    await expectLater(service.fetchDaily(from: from), throwsStateError);
    await expectLater(service.fetchHourly(from: from), throwsStateError);
    await expectLater(service.fetchNights(from: from), throwsStateError);
    expect(called, isFalse);
    service.close();
  });

  test('weather and currency requests never receive the ID token', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        request.url.host == 'api.frankfurter.dev' ? '[]' : '{"results":[]}',
        200,
      );
    });
    final weather = OpenMeteoService(client: client);
    final currency = FrankfurterService(client: client);

    await weather.searchLocations('Berlin');
    await currency.fetchCurrencies();
    expect(requests.map((request) => request.url.host), [
      'geocoding-api.open-meteo.com',
      'api.frankfurter.dev',
    ]);
    expect(
      requests.every(
        (request) => !request.headers.containsKey('Authorization'),
      ),
      isTrue,
    );
  });
}
