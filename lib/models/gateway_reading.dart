/// The versioned snapshot uploaded by the ESP8266. No energy/fault inference.
class GatewayReading {
  final bool dark;
  final List<bool> motion;
  final List<bool> ledOn;
  final DateTime observedAt;
  final DateTime receivedAt;
  final int sourceUptimeMs;
  int get unitCount => motion.length;

  const GatewayReading({
    required this.dark,
    required this.motion,
    required this.ledOn,
    required this.observedAt,
    required this.receivedAt,
    required this.sourceUptimeMs,
  });

  factory GatewayReading.parse(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected a gateway snapshot.');
    }
    final count = value['unitCount'];
    if (value['v'] != 1 ||
        count is! int ||
        count < 1 ||
        count > 4 ||
        value['dark'] is! bool) {
      throw const FormatException('Unsupported gateway snapshot.');
    }
    List<bool> flags(Object? raw) {
      final List<Object?> items;
      if (raw is List) {
        items = List<Object?>.from(raw);
      } else if (raw is Map && raw.length == count) {
        items = List.generate(count, (i) => raw['$i'] ?? raw[i]);
      } else {
        throw const FormatException('Invalid sensor list.');
      }
      if (items.length != count || items.any((item) => item is! bool)) {
        throw const FormatException('Invalid sensor values.');
      }
      return List<bool>.unmodifiable(items.cast<bool>());
    }

    int integer(String key) {
      final raw = value[key];
      if (raw is! int || raw < 0) throw FormatException('Invalid $key.');
      return raw;
    }

    final observed = integer('sourceObservedAtMs');
    final received = integer('serverReceivedAtMs');
    if (observed == 0 ||
        received == 0 ||
        observed > received + 60000 ||
        observed < received - 120000) {
      throw const FormatException('Invalid observation timestamps.');
    }
    return GatewayReading(
      dark: value['dark'] as bool,
      motion: flags(value['motion']),
      ledOn: flags(value['ledOn']),
      observedAt: DateTime.fromMillisecondsSinceEpoch(observed),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(received),
      sourceUptimeMs: integer('sourceUptimeMs'),
    );
  }

  bool isFresh(DateTime serverNow) {
    final age = serverNow.difference(observedAt).inMilliseconds;
    return age >= -60000 && age <= 30000;
  }
}
