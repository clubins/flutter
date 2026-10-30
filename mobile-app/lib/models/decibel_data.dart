class DecibelSensor {
  const DecibelSensor({
    required this.sensorId,
    required this.location,
    required this.types,
  });

  final String sensorId;
  final String location;
  final List<String> types;

  factory DecibelSensor.fromJson(Map<String, dynamic> json) => DecibelSensor(
    sensorId: json['sensorId'] as String,
    location: json['location'] as String? ?? 'Unknown',
    types: (json['types'] as List<dynamic>? ?? const []).cast<String>(),
  );
}

class DecibelReading {
  const DecibelReading({
    required this.time,
    required this.dba,
    required this.dbc,
  });

  final DateTime time;
  final double dba;
  final double dbc;

  factory DecibelReading.fromJson(Map<String, dynamic> json) => DecibelReading(
    time: DateTime.parse(json['time'] as String),
    dba: (json['dba'] as num).toDouble(),
    dbc: (json['dbc'] as num).toDouble(),
  );
}

class DecibelSensorHistory {
  const DecibelSensorHistory({required this.sensor, required this.readings});

  final DecibelSensor sensor;
  final List<DecibelReading> readings;
}

class DecibelHistory {
  const DecibelHistory({
    required this.from,
    required this.to,
    required this.points,
    required this.sensors,
  });

  final DateTime from;
  final DateTime to;
  final int points;
  final List<DecibelSensorHistory> sensors;
}
