class WeatherLocation {
  const WeatherLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country = '',
  });

  final String name;
  final double latitude;
  final double longitude;
  final String country;

  String get label => country.isEmpty ? name : '$name, $country';
}

class WeatherData {
  const WeatherData({
    required this.location,
    required this.current,
    required this.hourly,
  });

  final WeatherLocation location;
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
}

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
    required this.precipitation,
  });

  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final int weatherCode;
  final double windSpeed;
  final double precipitation;

  String get description {
    if (weatherCode == 0) return 'Clear sky';
    if ([1, 2, 3].contains(weatherCode)) return 'Partly cloudy';
    if ([45, 48].contains(weatherCode)) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 57) return 'Drizzle';
    if (weatherCode >= 61 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Mixed conditions';
  }
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.rain,
  });

  final DateTime time;
  final double temperature;
  final double rain;
}
