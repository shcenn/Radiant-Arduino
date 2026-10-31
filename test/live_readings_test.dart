import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:radiant/data/live_controller.dart';
import 'package:radiant/models/gateway_reading.dart';
import 'package:radiant/models/streetlight.dart';

Map<String, Object?> frame(int time, {int count = 1}) => {
  'v': 1,
  'unitCount': count,
  'dark': true,
  'motion': List.filled(count, true),
  'ledOn': List.filled(count, true),
  'sourceUptimeMs': 12345,
  'sourceObservedAtMs': time,
  'serverReceivedAtMs': time + 1000,
};

void main() {
  final now = DateTime.utc(2026, 10, 25, 12);
  test('Parses RTDB arrays and numeric-key objects for all four units', () {
    final input = frame(now.millisecondsSinceEpoch, count: 4);
    final reading = GatewayReading.parse(input);
    expect(reading.unitCount, 4);
    expect(reading.dark, isTrue);
    expect(reading.motion, everyElement(isTrue));
    input['motion'] = {'0': true, '1': false, '2': true, '3': false};
    expect(GatewayReading.parse(input).motion, [true, false, true, false]);
  });
  test('Rejects malformed frames instead of inventing states', () {
    for (final invalid in [
      null,
      {'v': 2},
      {
        ...frame(now.millisecondsSinceEpoch),
        'motion': [1],
      },
      {...frame(now.millisecondsSinceEpoch), 'unitCount': 2},
      {...frame(now.millisecondsSinceEpoch), 'sourceObservedAtMs': 0},
      {
        ...frame(now.millisecondsSinceEpoch),
        'motion': {'1': true},
      },
    ]) {
      expect(() => GatewayReading.parse(invalid), throwsFormatException);
    }
  });
  test(
    'Uses observation time to expire data, even if receipt time is recent',
    () {
      final reading = GatewayReading.parse(frame(now.millisecondsSinceEpoch));
      expect(reading.isFresh(now.add(const Duration(seconds: 30))), isTrue);
      expect(reading.isFresh(now.add(const Duration(seconds: 31))), isFalse);
    },
  );
  test(
    'App receipt starts now without disguising an old sensor observation',
    () async {
      final readings = StreamController<Object?>();
      final connection = StreamController<Object?>();
      final offset = StreamController<Object?>();
      var clock = now;
      final live = LiveController(
        readings: readings.stream,
        connection: connection.stream,
        serverOffset: offset.stream,
        clock: () => clock,
        tick: false,
        expectedUnits: 1,
      );
      connection.add(true);
      readings.add(
        frame(now.subtract(const Duration(seconds: 45)).millisecondsSinceEpoch),
      );
      await Future<void>.delayed(Duration.zero);
      expect(live.lastSynced, 'Just now');
      expect(live.lastSeen, '45 seconds ago');
      expect(live.online, isFalse);
      clock = now.add(const Duration(seconds: 1));
      expect(live.lastSynced, '1 second ago');
      expect(live.online, isFalse);
      readings.add(frame(clock.millisecondsSinceEpoch));
      await Future<void>.delayed(Duration.zero);
      expect(live.lastSynced, 'Just now');
      expect(live.online, isTrue);
      readings.add({'v': 999});
      await Future<void>.delayed(Duration.zero);
      expect(live.lastSynced, 'No updates yet');
      expect(live.online, isFalse);
      live.dispose();
      await readings.close();
      await connection.close();
      await offset.close();
    },
  );
  test(
    'Live controller expires readings without another database event',
    () async {
      final readings = StreamController<Object?>();
      final connection = StreamController<Object?>();
      final offset = StreamController<Object?>();
      var clock = now;
      final live = LiveController(
        readings: readings.stream,
        connection: connection.stream,
        serverOffset: offset.stream,
        clock: () => clock,
        tick: false,
        expectedUnits: 1,
      );
      connection.add(true);
      readings.add(frame(now.millisecondsSinceEpoch));
      await Future<void>.delayed(Duration.zero);
      expect(live.online, isTrue);
      expect(live.lights.single.status, StreetlightStatus.functional);
      clock = now.add(const Duration(seconds: 31));
      expect(live.online, isFalse);
      expect(live.lights.single.status, StreetlightStatus.offline);
      readings.add({...frame(clock.millisecondsSinceEpoch), 'dark': false});
      await Future<void>.delayed(Duration.zero);
      expect(live.online, isTrue);
      expect(live.lights.single.dark, isFalse);
      connection.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(live.online, isFalse);
      live.dispose();
      await readings.close();
      await connection.close();
      await offset.close();
    },
  );
}
