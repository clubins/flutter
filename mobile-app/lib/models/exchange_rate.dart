class Currency {
  const Currency({required this.code, required this.name});

  final String code;
  final String name;

  @override
  String toString() => '$code — $name';
}

class ExchangeRate {
  const ExchangeRate({
    required this.date,
    required this.base,
    required this.quote,
    required this.rate,
  });

  final DateTime date;
  final String base;
  final String quote;
  final double rate;
}
