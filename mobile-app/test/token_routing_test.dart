import 'package:clubins/services/clubins_api_service.dart';
import 'package:clubins/services/frankfurter_service.dart';
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
