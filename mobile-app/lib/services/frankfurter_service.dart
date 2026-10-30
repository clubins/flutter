import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/exchange_rate.dart';

class FrankfurterService {
  FrankfurterService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void close() => _client.close();

  Future<List<Currency>> fetchCurrencies() async {
    final response = await _client.get(
      Uri.https('api.frankfurter.dev', '/v2/currencies'),
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load currencies.');
    }
    final rows = jsonDecode(response.body) as List<dynamic>;
    return rows.map((item) {
      final json = item as Map<String, dynamic>;
      return Currency(
        code: json['iso_code'] as String,
        name: json['name'] as String,
      );
    }).toList()..sort((a, b) => a.code.compareTo(b.code));
  }

  Future<List<ExchangeRate>> fetchRates({
    required String base,
    required String quote,
    required DateTime from,
  }) async {
    final to = DateTime.now();
    final uri = Uri.https('api.frankfurter.dev', '/v2/rates', {
      'base': base,
      'quotes': quote,
      'from': _date(from),
      'to': _date(to),
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Could not load exchange rates.');
    }
    final rows = jsonDecode(response.body) as List<dynamic>;
    return rows.map((item) {
      final json = item as Map<String, dynamic>;
      return ExchangeRate(
        date: DateTime.parse(json['date'] as String),
        base: json['base'] as String? ?? base,
        quote: json['quote'] as String? ?? quote,
        rate: (json['rate'] as num).toDouble(),
      );
    }).toList();
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
