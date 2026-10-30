import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:intl/intl.dart';

import '../models/exchange_rate.dart';
import '../services/frankfurter_service.dart';
import '../widgets/charts.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/range_selector.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key, this.service});

  final FrankfurterService? service;

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  late final FrankfurterService _service;
  late final bool _ownsService;
  List<Currency> _currencies = [];
  List<ExchangeRate> _rates = [];
  String _base = 'EUR';
  String _quote = 'USD';
  String _range = '90D';
  Object? _error;
  bool _loading = true;
  bool _currencyLoadFailed = false;
  int _currencyRequest = 0;
  int _rateRequest = 0;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? FrankfurterService();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _currencyRequest++;
    _rateRequest++;
    if (_ownsService) _service.close();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final request = ++_currencyRequest;
    setState(() {
      _loading = true;
      _error = null;
      _currencyLoadFailed = false;
    });
    try {
      final currencies = await _service.fetchCurrencies();
      if (!mounted || request != _currencyRequest) {
        return;
      }
      setState(() => _currencies = currencies);
      await _loadRates();
    } catch (error) {
      if (mounted && request == _currencyRequest) {
        setState(() {
          _error = error;
          _loading = false;
          _currencyLoadFailed = true;
        });
      }
    }
  }

  Future<void> _loadRates() async {
    final request = ++_rateRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    final days = switch (_range) {
      '7D' => 7,
      '30D' => 30,
      '90D' => 90,
      _ => 365,
    };
    try {
      final rates = await _service.fetchRates(
        base: _base,
        quote: _quote,
        from: DateTime.now().subtract(Duration(days: days)),
      );
      if (mounted && request == _rateRequest) {
        setState(() {
          _rates = rates;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && request == _rateRequest) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        DashboardHeader(
          title: 'Currencies',
          onRefresh: _loading ? null : _loadRates,
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Exchange dashboard',
            style: Theme.of(
              context,
            ).typography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text('Reference rates from Frankfurter'),
          const SizedBox(height: 20),
          _pairControls(),
          const SizedBox(height: 20),
          if (_error != null) _errorCard(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _rates.isNotEmpty) ...[
            _RateSummary(rate: _rates.last),
            const SizedBox(height: 16),
            _historyCard(),
          ],
        ],
      ),
    );
  }

  Widget _pairControls() {
    final base = _currencyDropdown('Base', _base, (value) {
      if (value != null && value != _quote) {
        setState(() => _base = value);
        _loadRates();
      }
    });
    final quote = _currencyDropdown('Quote', _quote, (value) {
      if (value != null && value != _base) {
        setState(() => _quote = value);
        _loadRates();
      }
    });
    final swap = Tooltip(
      tooltip: (_) => const Text('Swap currencies'),
      child: Semantics(
        label: 'Swap currencies',
        button: true,
        child: IconButton.ghost(
          key: const ValueKey('swap-currencies'),
          onPressed: () {
            final oldBase = _base;
            setState(() {
              _base = _quote;
              _quote = oldBase;
            });
            _loadRates();
          },
          icon: const Icon(LucideIcons.arrowLeftRight),
        ),
      ),
    );
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                base,
                Align(alignment: Alignment.center, child: swap),
                quote,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: base),
              swap,
              Expanded(child: quote),
            ],
          );
        },
      ),
    );
  }

  Widget _currencyDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label).small().semiBold(),
        const SizedBox(height: 8),
        Semantics(
          label: '$label currency',
          child: Select<String>(
            value: value,
            enabled: _currencies.isNotEmpty,
            onChanged: onChanged,
            itemBuilder: (context, item) =>
                Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            popup: SelectPopup<String>(
              items: SelectItemList(
                children: [
                  for (final currency in _currencies)
                    SelectItemButton(
                      value: currency.code,
                      child: Text(currency.code),
                    ),
                ],
              ),
            ).call,
          ),
        ),
      ],
    );
  }

  Widget _errorCard() => DashboardErrorCard(
    title: _currencyLoadFailed
        ? 'Unable to load currencies'
        : 'Unable to load exchange rates',
    message: _error.toString(),
    onRetry: _currencyLoadFailed ? _loadCurrencies : _loadRates,
  );

  Widget _historyCard() {
    return Card(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('One unit of the base currency'),
            const SizedBox(height: 10),
            RangeSelector(
              value: _range,
              options: const [
                RangeOption('7D', '7D'),
                RangeOption('30D', '30D'),
                RangeOption('90D', '90D'),
                RangeOption('1Y', '1Y'),
              ],
              onChanged: _changeRange,
            ),
            const SizedBox(height: 20),
            SizedBox(height: 300, child: ExchangeRateChart(data: _rates)),
          ],
        ),
      ),
    );
  }

  void _changeRange(String value) {
    setState(() => _range = value);
    _loadRates();
  }
}

class _RateSummary extends StatelessWidget {
  const _RateSummary({required this.rate});
  final ExchangeRate rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.arrowLeftRight, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${rate.base} / ${rate.quote}',
                    style: Theme.of(context).typography.large,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rate.rate.toStringAsFixed(4),
              style: Theme.of(
                context,
              ).typography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            Text('As of ${DateFormat('MMM d, yyyy').format(rate.date)}'),
          ],
        ),
      ),
    );
  }
}
