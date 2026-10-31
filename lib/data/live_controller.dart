import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/gateway_reading.dart';
import '../config/monitoring_config.dart';
import '../models/streetlight.dart';

/// Owns a single gateway subscription and expires cached readings over time.
class LiveController extends ChangeNotifier {
  final DateTime Function() clock;
  final int expectedUnits;
  final Map<int, GatewayReading> _unitReadings = {};
  bool _snapshotPresent = false;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _timer;
  GatewayReading? reading;
  bool connected = false;
  bool loading = true;
  String? error;
  int _serverOffsetMs = 0;
  DateTime? _appReceivedAt;

  LiveController({
    required Stream<Object?> readings,
    required Stream<Object?> connection,
    required Stream<Object?> serverOffset,
    DateTime Function()? clock,
    bool tick = true,
    this.expectedUnits = configuredUnitCount,
  }) : assert(expectedUnits >= 1 && expectedUnits <= 4),
       clock = clock ?? DateTime.now {
    _subscriptions.add(
      readings.listen(
        (value) {
          loading = false;
          error = null;
          if (value == null) {
            _snapshotPresent = false;
            _appReceivedAt = null;
          } else {
            try {
              final parsed = GatewayReading.parse(value);
              reading = parsed;
              _snapshotPresent = true;
              for (var i = 0; i < parsed.unitCount; i++) {
                _unitReadings[i] = parsed;
              }
              _appReceivedAt = this.clock();
            } on FormatException {
              error = 'The gateway sent an unsupported reading.';
              _snapshotPresent = false;
              _appReceivedAt = null;
            }
          }
          notifyListeners();
        },
        onError: (Object failure) {
          loading = false;
          error = failure.toString().contains('permission-denied')
              ? 'This account does not have dashboard access. Contact the project administrator.'
              : 'Cannot read the gateway. Check your internet connection and try again.';
          notifyListeners();
        },
      ),
    );
    _subscriptions.add(
      connection.listen(
        (value) {
          connected = value == true;
          notifyListeners();
        },
        onError: (Object _) {
          connected = false;
          notifyListeners();
        },
      ),
    );
    _subscriptions.add(
      serverOffset.listen((value) {
        if (value is num) _serverOffsetMs = value.toInt();
        notifyListeners();
      }, onError: (Object _) {}),
    );
    if (tick) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => notifyListeners(),
      );
    }
  }

  DateTime get serverNow =>
      clock().add(Duration(milliseconds: _serverOffsetMs));
  bool get online =>
      error == null &&
      _snapshotPresent &&
      connected &&
      (reading?.isFresh(serverNow) ?? false);
  String get connectionLabel {
    if (error != null) return 'Connection needs attention';
    if (loading) return 'Connecting to Firebase...';
    if (!_snapshotPresent || reading == null) {
      return 'Waiting for a valid gateway reading';
    }
    if (!connected) return 'App disconnected - showing last reading';
    if (!online) return 'Gateway offline - readings are over 30 seconds old';
    if (serverNow.difference(reading!.observedAt) > delayedReadingAfter) {
      return 'Readings delayed - checking the gateway';
    }
    return 'Live readings from your streetlights';
  }

  /// App receipt age is distinct from the true source observation age.
  String get lastSynced {
    final received = _appReceivedAt;
    if (received == null) return 'No updates yet';
    final seconds = clock().difference(received).inSeconds;
    if (seconds < 1) return 'Just now';
    if (seconds == 1) return '1 second ago';
    if (seconds < 60) return '$seconds seconds ago';
    if (seconds < 3600) return '${seconds ~/ 60} minutes ago';
    return '${seconds ~/ 3600} hours ago';
  }

  String get lastSeen {
    final data = reading;
    if (data == null) return 'No readings yet';
    final seconds = serverNow.difference(data.observedAt).inSeconds;
    if (seconds < 1) return 'Just now';
    if (seconds < 60) return '$seconds seconds ago';
    if (seconds < 3600) return '${seconds ~/ 60} minutes ago';
    return '${seconds ~/ 3600} hours ago';
  }

  StreetlightStatus _status(int index) {
    if (!connected) return StreetlightStatus.offline;
    final data = reading;
    if (data != null && !data.isFresh(serverNow)) {
      return StreetlightStatus.offline;
    }
    if (error != null) return StreetlightStatus.warning;
    if (!_snapshotPresent || data == null) return StreetlightStatus.offline;
    if (index >= data.unitCount) return StreetlightStatus.warning;
    if (serverNow.difference(data.observedAt) > delayedReadingAfter) {
      return StreetlightStatus.warning;
    }
    // This checks controller commands, never physical bulb or PIR health.
    if ((!data.dark && data.ledOn[index]) ||
        (data.dark && data.motion[index] && !data.ledOn[index])) {
      return StreetlightStatus.warning;
    }
    return StreetlightStatus.functional;
  }

  String _reason(int index, StreetlightStatus status) {
    if (!connected) {
      return 'App disconnected from Firebase; unit state is unknown.';
    }
    final data = reading;
    if (data != null && !data.isFresh(serverNow)) {
      return 'Gateway telemetry expired; no fresh observation within 30 seconds.';
    }
    if (error != null) return error!;
    if (!_snapshotPresent || data == null) {
      return 'No valid telemetry received for this configured unit.';
    }
    if (index >= data.unitCount) {
      return 'Channel missing: gateway reports ${data.unitCount} of $expectedUnits configured units.';
    }
    if (serverNow.difference(data.observedAt) > delayedReadingAfter) {
      return 'Reading is over 15 seconds old; gateway updates are delayed.';
    }
    if (!data.dark && data.ledOn[index]) {
      return 'Control mismatch: LED commanded ON during daylight.';
    }
    if (data.dark && data.motion[index] && !data.ledOn[index]) {
      return 'Control mismatch: motion in darkness but LED commanded OFF.';
    }
    return 'Fresh motion and LED command received.';
  }

  List<Streetlight> get lights => List.generate(expectedUnits, (i) {
    final data = _unitReadings[i];
    final status = _status(i);
    final current =
        _snapshotPresent &&
        error == null &&
        connected &&
        reading != null &&
        i < reading!.unitCount &&
        reading!.isFresh(serverNow);
    return Streetlight(
      id: 'UNIT #${i + 1}',
      location: 'Prototype streetlight ${i + 1}',
      status: status,
      statusReason: _reason(i, status),
      lastObservedAt: data?.observedAt,
      currentTelemetry: current,
      brightnessPercent: data != null && data.ledOn[i] ? 100 : 0,
      motionDetected: data?.motion[i],
      dark: data?.dark,
      ledOn: data?.ledOn[i],
      tags: [
        if (data == null)
          'Awaiting telemetry'
        else if (!current)
          'Last reported state',
        if (data != null) data.dark ? 'Dark outside' : 'Daylight',
        if (data != null) data.motion[i] ? 'Motion detected' : 'No motion',
        if (data != null)
          data.ledOn[i] ? 'LED commanded ON' : 'LED commanded OFF',
      ],
    );
  });

  List<MonitoringAlert> get alerts {
    if (!connected) {
      return [
        const MonitoringAlert(
          'App connection lost',
          'All configured units remain listed. Their current state cannot be confirmed until Firebase reconnects.',
          StreetlightStatus.offline,
        ),
      ];
    }
    if (error != null) {
      return [
        MonitoringAlert(
          'Telemetry needs attention',
          error!,
          StreetlightStatus.warning,
        ),
      ];
    }
    if (!_snapshotPresent || reading == null) {
      return [
        const MonitoringAlert(
          'Waiting for gateway data',
          'No valid current snapshot is available. Check Uno power, the serial cable and the ESP connection.',
          StreetlightStatus.offline,
        ),
      ];
    }
    if (!reading!.isFresh(serverNow)) {
      return [
        const MonitoringAlert(
          'Gateway telemetry offline',
          'Readings expired after 30 seconds. Check both boards, the Uno-to-ESP link and Wi-Fi.',
          StreetlightStatus.offline,
        ),
      ];
    }
    return [
      for (var i = 0; i < expectedUnits; i++)
        if (_status(i) == StreetlightStatus.warning)
          MonitoringAlert(
            'UNIT #${i + 1} needs attention',
            _reason(i, StreetlightStatus.warning),
            StreetlightStatus.warning,
            unitIndex: i,
          ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
