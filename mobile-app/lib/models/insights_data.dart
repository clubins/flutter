// Typed payloads for the per-venue insights API
// (`/app/v0/venues/{venueId}/insights/*`); see the "Per-venue insights"
// build spec for the route table and the documented summary shape.
//
// Honesty rules the shapes encode:
// - A sensor with no readings in the window parses with `readings: 0` and
//   every metric block null — absent data is never rendered as zeros.
// - Every aggregate carries its coverage (first/last reading, capture %,
//   longest gap) so ingestion gaps stay visible next to the numbers.
// - A metric block is present only when at least one reading contributed
//   to it; fields are non-null unless documented otherwise.

/// The summary route's window choices.
enum InsightsWindow {
  sevenDays,
  thirtyDays;

  /// Query-parameter value the API expects.
  String get wireName => switch (this) {
    InsightsWindow.sevenDays => '7d',
    InsightsWindow.thirtyDays => '30d',
  };
}

/// A named dB(A) extreme and when it happened.
class InsightsPeak {
  const InsightsPeak({required this.dba, required this.time});

  final double dba;
  final DateTime time;

  factory InsightsPeak.fromJson(Map<String, dynamic> json) => InsightsPeak(
    dba: (json['dba'] as num).toDouble(),
    time: DateTime.parse(json['time'] as String),
  );
}

/// Sound above the sensor's quiet floor: level and exposure. [floorDba]
/// and [thresholdDba] are the derived quiet floor and activity threshold
/// for the aggregated window; per-day rows may omit them.
class InsightsActive {
  const InsightsActive({
    required this.meanDba,
    required this.minutes,
    required this.floorDba,
    required this.thresholdDba,
  });

  final double meanDba;
  final double minutes;
  final double? floorDba;
  final double? thresholdDba;

  factory InsightsActive.fromJson(Map<String, dynamic> json) => InsightsActive(
    meanDba: (json['meanDba'] as num).toDouble(),
    minutes: (json['minutes'] as num).toDouble(),
    floorDba: (json['floorDba'] as num?)?.toDouble(),
    thresholdDba: (json['thresholdDba'] as num?)?.toDouble(),
  );
}

/// Sound at or below the sensor's quiet floor.
class InsightsQuiet {
  const InsightsQuiet({required this.meanDba, required this.minutes});

  final double meanDba;
  final double minutes;

  factory InsightsQuiet.fromJson(Map<String, dynamic> json) => InsightsQuiet(
    meanDba: (json['meanDba'] as num).toDouble(),
    minutes: (json['minutes'] as num).toDouble(),
  );
}

/// Minutes at or above the fixed hearing-risk reference levels.
class InsightsThresholds {
  const InsightsThresholds({
    required this.above85Minutes,
    required this.above90Minutes,
    required this.above95Minutes,
  });

  final double above85Minutes;
  final double above90Minutes;
  final double above95Minutes;

  factory InsightsThresholds.fromJson(Map<String, dynamic> json) =>
      InsightsThresholds(
        above85Minutes: (json['above85Minutes'] as num).toDouble(),
        above90Minutes: (json['above90Minutes'] as num).toDouble(),
        above95Minutes: (json['above95Minutes'] as num).toDouble(),
      );
}

/// The C−A weighted gap, the venue's bass-heavy character.
class InsightsBassGap {
  const InsightsBassGap({required this.medianDb, required this.p90Db});

  final double medianDb;
  final double p90Db;

  factory InsightsBassGap.fromJson(Map<String, dynamic> json) =>
      InsightsBassGap(
        medianDb: (json['medianDb'] as num).toDouble(),
        p90Db: (json['p90Db'] as num).toDouble(),
      );
}

/// What a window's numbers actually rest on: first/last reading, capture
/// percentage against the expected cadence, and the longest ingestion gap.
class InsightsCoverage {
  const InsightsCoverage({
    required this.firstReading,
    required this.lastReading,
    required this.capturePct,
    required this.longestGapMinutes,
  });

  final DateTime firstReading;
  final DateTime lastReading;
  final double capturePct;
  final double longestGapMinutes;

  factory InsightsCoverage.fromJson(Map<String, dynamic> json) =>
      InsightsCoverage(
        firstReading: DateTime.parse(json['firstReading'] as String),
        lastReading: DateTime.parse(json['lastReading'] as String),
        capturePct: (json['capturePct'] as num).toDouble(),
        longestGapMinutes: (json['longestGapMinutes'] as num).toDouble(),
      );
}

/// Decibel sensor block of the summary route.
class InsightsDecibelSensor {
  const InsightsDecibelSensor({
    required this.sensorId,
    required this.location,
    required this.readings,
    required this.peak,
    required this.active,
    required this.quiet,
    required this.thresholds,
    required this.bassGap,
    required this.coverage,
  });

  final String sensorId;
  final String location;
  final int readings;
  final InsightsPeak? peak;
  final InsightsActive? active;
  final InsightsQuiet? quiet;
  final InsightsThresholds? thresholds;
  final InsightsBassGap? bassGap;
  final InsightsCoverage? coverage;

  factory InsightsDecibelSensor.fromJson(Map<String, dynamic> json) =>
      InsightsDecibelSensor(
        sensorId: json['sensorId'] as String,
        location: json['location'] as String? ?? 'Unknown',
        readings: (json['readings'] as num? ?? 0).toInt(),
        peak: _block(json['peak'], InsightsPeak.fromJson),
        active: _block(json['active'], InsightsActive.fromJson),
        quiet: _block(json['quiet'], InsightsQuiet.fromJson),
        thresholds: _block(json['thresholds'], InsightsThresholds.fromJson),
        bassGap: _block(json['bassGap'], InsightsBassGap.fromJson),
        coverage: _block(json['coverage'], InsightsCoverage.fromJson),
      );
}

/// Occupancy sensor block of the summary route (venue-wide totals).
class InsightsPaxSensor {
  const InsightsPaxSensor({
    required this.sensorId,
    required this.location,
    required this.readings,
    required this.maxOccupancy,
    required this.venueHours,
    required this.coverage,
  });

  final String sensorId;
  final String location;
  final int readings;
  final int? maxOccupancy;
  final double? venueHours;
  final InsightsCoverage? coverage;

  factory InsightsPaxSensor.fromJson(Map<String, dynamic> json) =>
      InsightsPaxSensor(
        sensorId: json['sensorId'] as String,
        location: json['location'] as String? ?? 'Unknown',
        readings: (json['readings'] as num? ?? 0).toInt(),
        maxOccupancy: (json['maxOccupancy'] as num?)?.toInt(),
        venueHours: (json['venueHours'] as num?)?.toDouble(),
        coverage: _block(json['coverage'], InsightsCoverage.fromJson),
      );
}

/// Weather sensor block of the summary route. Only identity, volume, and
/// coverage are modeled for v1 — the spec documents no metric field list
/// for weather sensors, so range fields land with the Go summary
/// implementation.
class InsightsWeatherSensor {
  const InsightsWeatherSensor({
    required this.sensorId,
    required this.location,
    required this.readings,
    required this.coverage,
  });

  final String sensorId;
  final String location;
  final int readings;
  final InsightsCoverage? coverage;

  factory InsightsWeatherSensor.fromJson(Map<String, dynamic> json) =>
      InsightsWeatherSensor(
        sensorId: json['sensorId'] as String,
        location: json['location'] as String? ?? 'Unknown',
        readings: (json['readings'] as num? ?? 0).toInt(),
        coverage: _block(json['coverage'], InsightsCoverage.fromJson),
      );
}

/// Per-sensor ingest health for the window: staleness, cadence, capture.
class InsightsHealth {
  const InsightsHealth({
    required this.sensorId,
    required this.location,
    required this.lastSeen,
    required this.staleMinutes,
    required this.medianIntervalS,
    required this.capturePct,
  });

  final String sensorId;
  final String location;
  final DateTime? lastSeen;
  final double? staleMinutes;
  final double? medianIntervalS;
  final double? capturePct;

  factory InsightsHealth.fromJson(Map<String, dynamic> json) => InsightsHealth(
    sensorId: json['sensorId'] as String,
    location: json['location'] as String? ?? 'Unknown',
    lastSeen: json['lastSeen'] == null
        ? null
        : DateTime.parse(json['lastSeen'] as String),
    staleMinutes: (json['staleMinutes'] as num?)?.toDouble(),
    medianIntervalS: (json['medianIntervalS'] as num?)?.toDouble(),
    capturePct: (json['capturePct'] as num?)?.toDouble(),
  );
}

/// Venue-wide KPIs for one window, plus per-sensor health and caveats.
class InsightsSummary {
  const InsightsSummary({
    required this.venueId,
    required this.window,
    required this.from,
    required this.to,
    required this.decibelSensors,
    required this.paxSensors,
    required this.weatherSensors,
    required this.health,
    required this.caveats,
  });

  final String venueId;
  final String window;
  final DateTime from;
  final DateTime to;
  final List<InsightsDecibelSensor> decibelSensors;
  final List<InsightsPaxSensor> paxSensors;
  final List<InsightsWeatherSensor> weatherSensors;
  final List<InsightsHealth> health;
  final List<String> caveats;

  factory InsightsSummary.fromJson(Map<String, dynamic> json) =>
      InsightsSummary(
        venueId: json['venueId'] as String,
        window: json['window'] as String,
        from: DateTime.parse(json['from'] as String),
        to: DateTime.parse(json['to'] as String),
        decibelSensors: _rows(
          (json['decibel'] as Map<String, dynamic>?)?['sensors'],
          InsightsDecibelSensor.fromJson,
        ),
        paxSensors: _rows(
          (json['pax'] as Map<String, dynamic>?)?['sensors'],
          InsightsPaxSensor.fromJson,
        ),
        weatherSensors: _rows(
          (json['weather'] as Map<String, dynamic>?)?['sensors'],
          InsightsWeatherSensor.fromJson,
        ),
        health: _rows(json['health'], InsightsHealth.fromJson),
        caveats: (json['caveats'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

/// One sensor's aggregates for one local day.
class InsightsDailyDay {
  const InsightsDailyDay({
    required this.sensorId,
    required this.location,
    required this.dateLocal,
    required this.readings,
    required this.active,
    required this.quiet,
    required this.peak,
    required this.thresholds,
    required this.coverage,
  });

  final String sensorId;
  final String location;

  /// Local calendar day (`yyyy-MM-dd`, venue timezone), not an instant.
  final String dateLocal;
  final int readings;
  final InsightsActive? active;
  final InsightsQuiet? quiet;
  final InsightsPeak? peak;
  final InsightsThresholds thresholds;
  final InsightsCoverage coverage;

  factory InsightsDailyDay.fromJson(Map<String, dynamic> json) =>
      InsightsDailyDay(
        sensorId: json['sensorId'] as String,
        location: json['location'] as String? ?? 'Unknown',
        dateLocal: json['dateLocal'] as String,
        readings: (json['readings'] as num? ?? 0).toInt(),
        active: _block(json['active'], InsightsActive.fromJson),
        quiet: _block(json['quiet'], InsightsQuiet.fromJson),
        peak: _block(json['peak'], InsightsPeak.fromJson),
        thresholds: InsightsThresholds.fromJson(json['thresholds']),
        coverage: InsightsCoverage.fromJson(json['coverage']),
      );
}

/// One row per sensor per local day over the requested range.
class InsightsDaily {
  const InsightsDaily({
    required this.venueId,
    required this.from,
    required this.to,
    required this.days,
  });

  final String venueId;
  final DateTime from;
  final DateTime to;
  final List<InsightsDailyDay> days;

  factory InsightsDaily.fromJson(Map<String, dynamic> json) => InsightsDaily(
    venueId: json['venueId'] as String,
    from: DateTime.parse(json['from'] as String),
    to: DateTime.parse(json['to'] as String),
    days: _rows(json['days'], InsightsDailyDay.fromJson),
  );
}

/// The part of the week an hourly row aggregates.
enum InsightsSplit { all, weekday, weekend }

/// One sensor's profile for one local hour of day (mean is energy-domain).
class InsightsHourlyRow {
  const InsightsHourlyRow({
    required this.sensorId,
    required this.location,
    required this.hourLocal,
    required this.readings,
    required this.meanDba,
    required this.p90Dba,
    required this.maxDba,
    required this.pctActive,
    required this.medianBassGapDb,
    required this.minutesAbove85,
    required this.minutesAbove90,
    required this.minutesAbove95,
  });

  final String sensorId;
  final String location;

  /// Local hour of day, 0–23 (venue timezone).
  final int hourLocal;
  final int readings;
  final double meanDba;
  final double p90Dba;
  final double maxDba;
  final double pctActive;

  /// Null when no reading in the bucket carries both A- and C-weighting.
  final double? medianBassGapDb;
  final double minutesAbove85;
  final double minutesAbove90;
  final double minutesAbove95;

  factory InsightsHourlyRow.fromJson(Map<String, dynamic> json) =>
      InsightsHourlyRow(
        sensorId: json['sensorId'] as String,
        location: json['location'] as String? ?? 'Unknown',
        hourLocal: (json['hourLocal'] as num).toInt(),
        readings: (json['readings'] as num? ?? 0).toInt(),
        meanDba: (json['meanDba'] as num).toDouble(),
        p90Dba: (json['p90Dba'] as num).toDouble(),
        maxDba: (json['maxDba'] as num).toDouble(),
        pctActive: (json['pctActive'] as num).toDouble(),
        medianBassGapDb: (json['medianBassGapDb'] as num?)?.toDouble(),
        minutesAbove85: (json['minutesAbove85'] as num? ?? 0).toDouble(),
        minutesAbove90: (json['minutesAbove90'] as num? ?? 0).toDouble(),
        minutesAbove95: (json['minutesAbove95'] as num? ?? 0).toDouble(),
      );
}

/// Hour-of-day profiles over the requested range and split.
class InsightsHourly {
  const InsightsHourly({
    required this.venueId,
    required this.from,
    required this.to,
    required this.split,
    required this.hours,
  });

  final String venueId;
  final DateTime from;
  final DateTime to;
  final InsightsSplit split;
  final List<InsightsHourlyRow> hours;

  factory InsightsHourly.fromJson(Map<String, dynamic> json) => InsightsHourly(
    venueId: json['venueId'] as String,
    from: DateTime.parse(json['from'] as String),
    to: DateTime.parse(json['to'] as String),
    split: InsightsSplit.values.byName(json['split'] as String),
    hours: _rows(json['hours'], InsightsHourlyRow.fromJson),
  );
}

/// One night (18:00–06:00 local) of one sensor, ranked by active minutes.
class InsightsNight {
  const InsightsNight({
    required this.sensorId,
    required this.location,
    required this.nightOf,
    required this.weekday,
    required this.activeMinutes,
    required this.activeMeanDba,
    required this.peakDba,
    required this.minutesAbove85,
  });

  final String sensorId;
  final String location;

  /// Local date the night started on (`yyyy-MM-dd`).
  final String nightOf;
  final String weekday;
  final double activeMinutes;
  final double activeMeanDba;
  final double peakDba;
  final double minutesAbove85;

  factory InsightsNight.fromJson(Map<String, dynamic> json) => InsightsNight(
    sensorId: json['sensorId'] as String,
    location: json['location'] as String? ?? 'Unknown',
    nightOf: json['nightOf'] as String,
    weekday: json['weekday'] as String,
    activeMinutes: (json['activeMinutes'] as num).toDouble(),
    activeMeanDba: (json['activeMeanDba'] as num).toDouble(),
    peakDba: (json['peakDba'] as num).toDouble(),
    minutesAbove85: (json['minutesAbove85'] as num? ?? 0).toDouble(),
  );
}

/// The busiest nights over the requested range.
class InsightsNights {
  const InsightsNights({
    required this.venueId,
    required this.from,
    required this.to,
    required this.nights,
  });

  final String venueId;
  final DateTime from;
  final DateTime to;
  final List<InsightsNight> nights;

  factory InsightsNights.fromJson(Map<String, dynamic> json) => InsightsNights(
    venueId: json['venueId'] as String,
    from: DateTime.parse(json['from'] as String),
    to: DateTime.parse(json['to'] as String),
    nights: _rows(json['nights'], InsightsNight.fromJson),
  );
}

/// Parses an optional metric block: null JSON stays null ("honest empty"),
/// a present block must fully parse.
T? _block<T>(Object? json, T Function(Map<String, dynamic> json) parse) =>
    json == null ? null : parse(json as Map<String, dynamic>);

/// Reads an optional JSON array as parsed rows; absent arrays parse as
/// empty. Every element must be a JSON object.
List<T> _rows<T>(Object? json, T Function(Map<String, dynamic> json) parse) =>
    (json as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(parse)
        .toList();
