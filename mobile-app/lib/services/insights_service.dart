import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/insights_data.dart';
import 'clubins_api_service.dart';

/// Client for the per-venue insights routes on the public Clubins API
/// (https://api.clubins.de): `/app/v0/venues/{venueId}/insights/*`.
///
/// Same security contract as [ClubinsApiService]: the ID token is attached
/// only to api.clubins.de requests and redirects are never followed.
class InsightsService {
  InsightsService({required String? Function() idToken, http.Client? client})
    : _idToken = idToken,
      _client = client ?? http.Client();

  final String? Function() _idToken;
  final http.Client _client;

  void close() => _client.close();

  /// Venue-wide KPIs, per-sensor health, and caveats for the last
  /// [window] (7 or 30 days).
  Future<InsightsSummary> fetchSummary({
    InsightsWindow window = InsightsWindow.thirtyDays,
  }) async {
    final uri = Uri.https(_host, _path('summary'), {'window': window.wireName});
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load insights summary.');
    }
    return InsightsSummary.fromJson(_decode(response));
  }

  /// One row per sensor per local day between [from] and [to] (at most
  /// 30 days apart; [to] defaults to now).
  Future<InsightsDaily> fetchDaily({
    required DateTime from,
    DateTime? to,
  }) async {
    final response = await _get(_rangeUri('daily', from, to));
    if (response.statusCode != 200) {
      throw Exception('Could not load daily insights.');
    }
    return InsightsDaily.fromJson(_decode(response));
  }

  /// Hour-of-day profiles between [from] and [to], optionally split by
  /// [split] (weekday vs weekend).
  Future<InsightsHourly> fetchHourly({
    required DateTime from,
    DateTime? to,
    InsightsSplit split = InsightsSplit.all,
  }) async {
    final uri = _rangeUri(
      'hourly',
      from,
      to,
    ).replace(queryParameters: {..._rangeQuery(from, to), 'split': split.name});
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load hourly insights.');
    }
    return InsightsHourly.fromJson(_decode(response));
  }

  /// The busiest nights between [from] and [to], ranked by active minutes
  /// inside the 18:00–06:00 local night window. [limit] caps the list
  /// (1–31; the API default is 10).
  Future<InsightsNights> fetchNights({
    required DateTime from,
    DateTime? to,
    int limit = 10,
  }) async {
    if (limit < 1 || limit > 31) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 31');
    }
    final uri = _rangeUri(
      'nights',
      from,
      to,
    ).replace(queryParameters: {..._rangeQuery(from, to), 'limit': '$limit'});
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load busiest nights.');
    }
    return InsightsNights.fromJson(_decode(response));
  }

  static const _host = 'api.clubins.de';

  String _path(String route) =>
      '/app/v0/venues/${ClubinsApiService.venueId}/insights/$route';

  Map<String, String> _rangeQuery(DateTime from, DateTime? to) => {
    'from': from.toUtc().toIso8601String(),
    if (to != null) 'to': to.toUtc().toIso8601String(),
  };

  Uri _rangeUri(String route, DateTime from, DateTime? to) =>
      Uri.https(_host, _path(route), _rangeQuery(from, to));

  Map<String, dynamic> _decode(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<http.Response> _get(Uri uri) async {
    if (uri.scheme != 'https' || uri.host != _host) {
      throw StateError('Clubins API requests must use $_host.');
    }
    final token = _idToken();
    if (token == null) throw StateError('Staff login has expired.');
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $token';
    return http.Response.fromStream(await _client.send(request));
  }
}
