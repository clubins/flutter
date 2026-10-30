import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_data.dart';

class OpenMeteoService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<List<WeatherLocation>> searchLocations(String query) async {
    if (query.trim().isEmpty) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query.trim(),
      'count': '8',
      'language': 'en',
      'format': 'json',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not search for locations.');
    }
    final results =
        (jsonDecode(response.body) as Map<String, dynamic>)['results']
            as List<dynamic>? ??
        [];
    return results.map((item) {
      final json = item as Map<String, dynamic>;
      return WeatherLocation(
        name: json['name'] as String? ?? 'Unknown',
        country: json['country'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  Future<WeatherData> fetchWeather(WeatherLocation location) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,precipitation',
      'hourly': 'temperature_2m,rain',
      'forecast_days': '14',
      'timezone': 'auto',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load weather data.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List<dynamic>).cast<String>();
    final temperatures = (hourly['temperature_2m'] as List<dynamic>)
        .cast<num>();
    final rain = (hourly['rain'] as List<dynamic>).cast<num>();
    return WeatherData(
      location: location,
      current: CurrentWeather(
        time: DateTime.parse(current['time'] as String),
        temperature: (current['temperature_2m'] as num).toDouble(),
        apparentTemperature: (current['apparent_temperature'] as num)
            .toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        precipitation: (current['precipitation'] as num).toDouble(),
      ),
      hourly: [
        for (var i = 0; i < times.length; i++)
          HourlyWeather(
            time: DateTime.parse(times[i]),
            temperature: temperatures[i].toDouble(),
            rain: rain[i].toDouble(),
          ),
      ],
    );
  }
}
