import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/decibel_data.dart';

/// Client for the public Clubins API (https://api.clubins.de).
class ClubinsApiService {
  ClubinsApiService({required String? Function() idToken, http.Client? client})
    : _idToken = idToken,
      _client = client ?? http.Client();

  final String? Function() _idToken;
  final http.Client _client;

  void close() => _client.close();

  /// The demo venue (Skatehalle). Hardcoded for now.
  static const venueId = '9c3f1e42-7a6b-4d18-9f52-3e0c8b7a5d61';

  Future<List<DecibelSensor>> fetchSensors() async {
    final uri = Uri.https('api.clubins.de', '/app/v0/venues/$venueId/sensors');
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load sensors.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final sensors = (json['sensors'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return sensors.map(DecibelSensor.fromJson).toList();
  }

  Future<DecibelHistory> fetchHistory({
    required DateTime from,
    DateTime? to,
    int points = 500,
  }) async {
    final query = <String, String>{
      'from': from.toUtc().toIso8601String(),
      'points': '$points',
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    final uri = Uri.https(
      'api.clubins.de',
      '/app/v0/venues/$venueId/history/decibel',
      query,
    );
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load decibel history.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final sensors = (json['sensors'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return DecibelHistory(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      points: (json['points'] as num).toInt(),
      sensors: [
        for (final sensor in sensors)
          DecibelSensorHistory(
            sensor: DecibelSensor.fromJson(sensor),
            readings: (sensor['readings'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>()
                .map(DecibelReading.fromJson)
                .toList(),
          ),
      ],
    );
  }

  Future<http.Response> _get(Uri uri) async {
    if (uri.scheme != 'https' || uri.host != 'api.clubins.de') {
      throw StateError('Clubins API requests must use api.clubins.de.');
    }
    final token = _idToken();
    if (token == null) throw StateError('Staff login has expired.');
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $token';
    return http.Response.fromStream(await _client.send(request));
  }
}
