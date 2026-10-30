import 'dart:async';
import 'package:flutter/services.dart' show rootBundle, FontLoader;

import 'package:clubins/models/exchange_rate.dart';
import 'package:clubins/models/weather_data.dart';
import 'package:clubins/pages/currency_page.dart';
import 'package:clubins/pages/weather_page.dart';
import 'package:clubins/services/frankfurter_service.dart';
import 'package:clubins/services/open_meteo_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Use the shipped font so layout tests catch real control widths.
  setUpAll(() async {
    final fonts = FontLoader('packages/shadcn_flutter/GeistSans');
    for (final weight in ['Regular', 'Bold']) {
      fonts.addFont(
        rootBundle.load('packages/shadcn_flutter/lib/fonts/Geist-$weight.otf'),
      );
    }
    await fonts.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scale in [1.0, 1.5]) {
    testWidgets('dashboards fit a narrow screen at text scale $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in <Widget>[
        WeatherPage(service: _WeatherService()),
        CurrencyPage(service: _RetryCurrencyService()..currencyRequests = 1),
      ]) {
        await tester.pumpWidget(
          ShadcnApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: page,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  testWidgets('weather search ignores an older response', (tester) async {
    final service = _WeatherService();
    await tester.pumpWidget(ShadcnApp(home: WeatherPage(service: service)));
    await tester.pumpAndSettle();

    expect(service.searches, isEmpty);
    await tester.enterText(find.byType(TextField), 'Pa');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.pump(const Duration(milliseconds: 301));

    service.searches['Paris']!.complete([
      const WeatherLocation(
        name: 'Paris',
        country: 'France',
        latitude: 48.86,
        longitude: 2.35,
      ),
    ]);
    await tester.pump();
    expect(find.text('Paris, France'), findsOneWidget);

    service.searches['Pa']!.complete([
      const WeatherLocation(
        name: 'Padua',
        country: 'Italy',
        latitude: 45.41,
        longitude: 11.88,
      ),
    ]);
    await tester.pump();
    expect(find.text('Paris, France'), findsOneWidget);
    expect(find.text('Padua, Italy'), findsNothing);

    await tester.tap(find.text('Paris, France'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 301));
    expect(service.searches.keys, ['Pa', 'Paris']);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Paris',
    );
  });

  testWidgets('weather charts start at the current forecast hour', (
    tester,
  ) async {
    final service = _WeatherService();
    await tester.pumpWidget(ShadcnApp(home: WeatherPage(service: service)));
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.first.y, 18);
  });

  testWidgets('currency rates ignore an older response', (tester) async {
    final service = _CurrencyService();
    await tester.pumpWidget(ShadcnApp(home: CurrencyPage(service: service)));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('swap-currencies')));
    await tester.pump();
    expect(service.rateRequests, hasLength(2));
    expect(
      tester
          .widgetList<Select<String>>(find.byType(Select<String>))
          .map((select) => select.value),
      ['USD', 'EUR'],
    );

    service.rateRequests[1].complete([
      ExchangeRate(
        date: DateTime(2026, 1, 2),
        base: 'USD',
        quote: 'EUR',
        rate: 0.85,
      ),
    ]);
    await tester.pump();
    expect(find.text('USD / EUR'), findsOneWidget);

    service.rateRequests[0].complete([
      ExchangeRate(
        date: DateTime(2026, 1, 1),
        base: 'EUR',
        quote: 'USD',
        rate: 1.2,
      ),
    ]);
    await tester.pump();
    expect(find.text('USD / EUR'), findsOneWidget);
    expect(find.text('EUR / USD'), findsNothing);
  });

  testWidgets('currency select opens and updates its controlled value', (
    tester,
  ) async {
    final service = _CurrencyService();
    await tester.pumpWidget(ShadcnApp(home: CurrencyPage(service: service)));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(Select<String>).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('GBP').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widgetList<Select<String>>(find.byType(Select<String>))
          .map((select) => select.value),
      ['GBP', 'USD'],
    );
    expect(service.rateRequests, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('currency metadata failures retry the metadata request', (
    tester,
  ) async {
    final service = _RetryCurrencyService();
    await tester.pumpWidget(ShadcnApp(home: CurrencyPage(service: service)));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load currencies'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(service.currencyRequests, 2);
    expect(find.text('EUR / USD'), findsOneWidget);
  });
}

class _WeatherService extends OpenMeteoService {
  final searches = <String, Completer<List<WeatherLocation>>>{};

  @override
  Future<List<WeatherLocation>> searchLocations(String query) =>
      (searches[query] ??= Completer<List<WeatherLocation>>()).future;

  @override
  Future<WeatherData> fetchWeather(WeatherLocation location) async {
    final start = DateTime(2026, 1, 1);
    return WeatherData(
      location: location,
      current: CurrentWeather(
        time: start.add(const Duration(hours: 18, minutes: 20)),
        temperature: 18,
        apparentTemperature: 18,
        humidity: 50,
        weatherCode: 0,
        windSpeed: 5,
        precipitation: 0,
      ),
      hourly: [
        for (var hour = 0; hour < 120; hour++)
          HourlyWeather(
            time: start.add(Duration(hours: hour)),
            temperature: hour.toDouble(),
            rain: 0,
          ),
      ],
    );
  }
}

class _CurrencyService extends FrankfurterService {
  final rateRequests = <Completer<List<ExchangeRate>>>[];

  @override
  Future<List<Currency>> fetchCurrencies() async => const [
    Currency(code: 'EUR', name: 'Euro'),
    Currency(code: 'USD', name: 'US Dollar'),
    Currency(code: 'GBP', name: 'Pound Sterling'),
  ];

  @override
  Future<List<ExchangeRate>> fetchRates({
    required String base,
    required String quote,
    required DateTime from,
  }) {
    final completer = Completer<List<ExchangeRate>>();
    rateRequests.add(completer);
    return completer.future;
  }
}

class _RetryCurrencyService extends FrankfurterService {
  int currencyRequests = 0;

  @override
  Future<List<Currency>> fetchCurrencies() async {
    currencyRequests++;
    if (currencyRequests == 1) throw Exception('metadata unavailable');
    return const [
      Currency(code: 'EUR', name: 'Euro'),
      Currency(code: 'USD', name: 'US Dollar'),
    ];
  }

  @override
  Future<List<ExchangeRate>> fetchRates({
    required String base,
    required String quote,
    required DateTime from,
  }) async => [
    ExchangeRate(
      date: DateTime(2026, 1, 1),
      base: base,
      quote: quote,
      rate: 1.1,
    ),
  ];
}
