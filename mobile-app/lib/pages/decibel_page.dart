import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:intl/intl.dart';

import '../models/decibel_data.dart';
import '../services/clubins_api_service.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/decibel_charts.dart';
import '../widgets/range_selector.dart';

class DecibelPage extends StatefulWidget {
  const DecibelPage({super.key, required this.service});

  final ClubinsApiService service;

  @override
  State<DecibelPage> createState() => _DecibelPageState();
}

class _DecibelPageState extends State<DecibelPage> {
  late final ClubinsApiService _api;
  List<DecibelSensor>? _sensors;
  DecibelHistory? _history;
  String _range = '24H';
  bool _loading = true;
  Object? _error;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.service;
    _load();
  }

  @override
  void dispose() {
    _loadRequest++;
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sensors = await _api.fetchSensors();
      final from = switch (_range) {
        '6H' => DateTime.now().toUtc().subtract(const Duration(hours: 6)),
        '24H' => DateTime.now().toUtc().subtract(const Duration(hours: 24)),
        '7D' => DateTime.now().toUtc().subtract(const Duration(days: 7)),
        _ => DateTime.now().toUtc().subtract(const Duration(days: 30)),
      };
      final history = await _api.fetchHistory(from: from);
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _sensors = sensors;
        _history = history;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        DashboardHeader(title: 'Decibel', onRefresh: _loading ? null : _load),
      ],
      child: RefreshTrigger(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Sound level dashboard',
              style: Theme.of(
                context,
              ).typography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Live decibel sensors at the Skatehalle',
              style: Theme.of(context).typography.base,
            ),
            const SizedBox(height: 20),
            _selector(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              DashboardErrorCard(
                title: 'Unable to load decibel data',
                message: _error.toString(),
                onRetry: _load,
              )
            else ...[
              _sensorSummary(),
              const SizedBox(height: 16),
              _chartCard(
                title: 'Sound level',
                subtitle: 'dB(A) readings per sensor',
                child: DecibelChart(series: _history?.sensors ?? const []),
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
      RangeOption('6H', '6H'),
      RangeOption('24H', '24H'),
      RangeOption('7D', '7D'),
      RangeOption('30D', '30D'),
    ],
    onChanged: (value) {
      setState(() => _range = value);
      _load();
    },
  );

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) => Card(
    padding: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).typography.h4),
          Text(subtitle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );

  Widget _sensorSummary() {
    final sensors = _sensors ?? const [];
    final decibelSensors = sensors
        .where((sensor) => sensor.types.contains('decibel'))
        .toList();
    final history = _history;
    return Card(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensors', style: Theme.of(context).typography.h4),
            const SizedBox(height: 8),
            if (decibelSensors.isEmpty)
              const Text('No active decibel sensors found.')
            else
              for (final sensor in decibelSensors)
                Basic(
                  leading: const Icon(LucideIcons.audioLines),
                  title: Text(sensor.location),
                  subtitle: Text(
                    'Last reading: ${_lastReadingLabel(sensor.sensorId, history)}',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _lastReadingLabel(String sensorId, DecibelHistory? history) {
    final readings = history == null
        ? const <DecibelReading>[]
        : history.sensors
              .where((s) => s.sensor.sensorId == sensorId)
              .expand((s) => s.readings)
              .toList();
    if (readings.isEmpty) return 'no data';
    final last = readings.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
    return '${last.dba.toStringAsFixed(1)} dB(A) at '
        '${DateFormat('HH:mm').format(last.time.toLocal())}';
  }
}
