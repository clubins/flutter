import 'dart:async';
import 'dart:convert';

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/weather_data.dart';
import '../services/open_meteo_service.dart';
import '../widgets/charts.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/range_selector.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key, this.service});

  final OpenMeteoService? service;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late final OpenMeteoService _service;
  late final bool _ownsService;
  final _searchController = TextEditingController();
  final _defaultLocation = const WeatherLocation(
    name: 'Berlin',
    country: 'Germany',
    latitude: 52.52,
    longitude: 13.41,
  );
  WeatherData? _weather;
  List<WeatherLocation> _locations = [];
  Object? _error;
  String _range = '3D';
  bool _searching = false;
  bool _settingSearchText = false;
  bool _loading = true;
  Timer? _searchDebounce;
  int _searchRequest = 0;
  int _weatherRequest = 0;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? OpenMeteoService();
    _restoreLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchRequest++;
    _weatherRequest++;
    if (_ownsService) _service.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restoreLocation() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('last_weather_location');
    WeatherLocation location = _defaultLocation;
    if (saved != null) {
      try {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        location = WeatherLocation(
          name: json['name'] as String,
          country: json['country'] as String? ?? '',
          latitude: (json['latitude'] as num).toDouble(),
          longitude: (json['longitude'] as num).toDouble(),
        );
      } catch (_) {
        // Ignore a stale preference and use the default location.
      }
    }
    if (!mounted) return;
    _setSearchText(location.name);
    _load(location);
  }

  Future<void> _saveLocation(WeatherLocation location) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'last_weather_location',
      jsonEncode({
        'name': location.name,
        'country': location.country,
        'latitude': location.latitude,
        'longitude': location.longitude,
      }),
    );
  }

  Future<void> _load(WeatherLocation location) async {
    final request = ++_weatherRequest;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final result = await _service.fetchWeather(location);
      if (mounted && request == _weatherRequest) {
        setState(() {
          _weather = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && request == _weatherRequest) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  // shadcn reports programmatic controller edits through onChanged too.
  void _setSearchText(String value) {
    _settingSearchText = true;
    try {
      _searchController.text = value;
    } finally {
      _settingSearchText = false;
    }
  }

  void _search(String value) {
    if (_settingSearchText) return;
    _searchDebounce?.cancel();
    final request = ++_searchRequest;
    if (value.trim().length < 2) {
      setState(() {
        _locations = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(value, request),
    );
  }

  Future<void> _performSearch(String value, int request) async {
    try {
      final results = await _service.searchLocations(value);
      if (mounted && request == _searchRequest) {
        setState(() => _locations = results);
      }
    } catch (_) {
      if (mounted && request == _searchRequest) {
        setState(() => _locations = []);
      }
    } finally {
      if (mounted && request == _searchRequest) {
        setState(() => _searching = false);
      }
    }
  }

  List<HourlyWeather> get _visibleHours {
    final weather = _weather;
    final all = weather?.hourly ?? [];
    final hours = switch (_range) {
      '24H' => 24,
      '3D' => 72,
      '7D' => 168,
      _ => 336,
    };
    if (weather == null) return const [];
    final current = weather.current.time;
    final currentHour = DateTime(
      current.year,
      current.month,
      current.day,
      current.hour,
    );
    return all
        .where((reading) => !reading.time.isBefore(currentHour))
        .take(hours)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    return Scaffold(
      headers: [
        DashboardHeader(
          title: 'Weather',
          onRefresh: weather == null ? null : () => _load(weather.location),
        ),
      ],
      child: RefreshTrigger(
        onRefresh: () => _load(weather?.location ?? _defaultLocation),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Forecast dashboard',
              style: Theme.of(
                context,
              ).typography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Open-Meteo forecast data',
              style: Theme.of(context).typography.base,
            ),
            const SizedBox(height: 20),
            _locationSearch(),
            if (_loading && weather != null) const LinearProgressIndicator(),
            if (_error != null)
              DashboardErrorCard(
                title: 'Unable to load weather',
                message: _error.toString(),
                onRetry: () => _load(weather?.location ?? _defaultLocation),
              ),
            if (weather == null && _error == null && _loading)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (weather != null) ...[
              _CurrentCard(weather: weather),
              const SizedBox(height: 20),
              _ChartCard(
                title: 'Temperature',
                subtitle: 'Hourly temperature in °C',
                selector: _selector(),
                child: SizedBox(
                  height: 280,
                  child: TemperatureChart(data: _visibleHours),
                ),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Rain',
                subtitle: 'Hourly rain accumulation in mm',
                selector: _selector(),
                child: SizedBox(
                  height: 280,
                  child: RainChart(data: _visibleHours),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selector() => RangeSelector(
    value: _range,
    options: const [
      RangeOption('24H', '24H'),
      RangeOption('3D', '3D'),
      RangeOption('7D', '7D'),
      RangeOption('14D', '14D'),
    ],
    onChanged: (value) => setState(() => _range = value),
  );

  Widget _locationSearch() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        label: 'Search city',
        child: TextField(
          controller: _searchController,
          onChanged: _search,
          placeholder: const Text('Search city, e.g. Amsterdam'),
          features: [
            const InputFeature.leading(Icon(LucideIcons.search)),
            if (_searching)
              const InputFeature.trailing(
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      if (_locations.isNotEmpty)
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final location in _locations)
                GhostButton(
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchRequest++;
                    _setSearchText(location.name);
                    setState(() {
                      _locations = [];
                      _searching = false;
                    });
                    _saveLocation(location);
                    _load(location);
                  },
                  child: Text(location.label),
                ),
            ],
          ),
        ),
    ],
  );
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.weather});
  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    return Card(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weather.location.label,
              style: Theme.of(context).typography.h4,
            ),
            Text(DateFormat('EEE, MMM d • HH:mm').format(current.time)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(LucideIcons.sun, size: 48),
                Text(
                  '${current.temperature.toStringAsFixed(1)}°',
                  style: Theme.of(
                    context,
                  ).typography.h1.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(current.description),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text(
                  'Feels ${current.apparentTemperature.toStringAsFixed(1)}°',
                ),
                Text('Humidity ${current.humidity.toStringAsFixed(0)}%'),
                Text('Wind ${current.windSpeed.toStringAsFixed(0)} km/h'),
                Text('Rain ${current.precipitation.toStringAsFixed(1)} mm'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.selector,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget selector;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    padding: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).typography.h4),
              Text(subtitle),
              const SizedBox(height: 10),
              selector,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}
