import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radiant/data/live_controller.dart';
import 'package:radiant/models/streetlight.dart';
import 'package:radiant/screens/map/map_screen.dart';

Map<String, Object?> snapshot(
  DateTime at, {
  int count = 4,
  bool dark = true,
  bool motion = false,
  bool led = false,
}) => {
  'v': 1,
  'unitCount': count,
  'dark': dark,
  'motion': List.filled(count, motion),
  'ledOn': List.filled(count, led),
  'sourceUptimeMs': 12345,
  'sourceObservedAtMs': at.millisecondsSinceEpoch,
  'serverReceivedAtMs': at.millisecondsSinceEpoch,
};

class Harness {
  Harness() {
    live;
  }
  final readings = StreamController<Object?>(sync: true),
      connection = StreamController<Object?>(sync: true),
      offset = StreamController<Object?>(sync: true);
  DateTime now = DateTime.utc(2026, 10, 27, 8);
  late final live = LiveController(
    readings: readings.stream,
    connection: connection.stream,
    serverOffset: offset.stream,
    clock: () => now,
    tick: false,
  );
  Future<void> publish(Object? data) async {
    connection.add(true);
    readings.add(data);
  }

  Future<void> close() async {
    live.dispose();
    await readings.close();
    await connection.close();
    await offset.close();
  }
}

void main() {
  test(
    'Four configured units exist before telemetry with unknown values',
    () async {
      final h = Harness();
      expect(h.live.lights.length, 4);
      expect(
        h.live.lights.map((l) => l.status),
        everyElement(StreetlightStatus.offline),
      );
      expect(h.live.lights.map((l) => l.ledOn), everyElement(isNull));
      expect(h.live.lights.map((l) => l.motionDetected), everyElement(isNull));
      await h.close();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
  test('No motion is healthy; delayed warning recovers and expires', () async {
    final h = Harness();
    await h.publish(snapshot(h.now));
    expect(
      h.live.lights.map((l) => l.status),
      everyElement(StreetlightStatus.functional),
    );
    expect(h.live.alerts, isEmpty);
    h.now = h.now.add(const Duration(seconds: 16));
    expect(
      h.live.lights.map((l) => l.status),
      everyElement(StreetlightStatus.warning),
    );
    expect(h.live.alerts, hasLength(4));
    h.now = h.now.add(const Duration(seconds: 15));
    expect(
      h.live.lights.map((l) => l.status),
      everyElement(StreetlightStatus.offline),
    );
    await h.publish(snapshot(h.now));
    expect(
      h.live.lights.map((l) => l.status),
      everyElement(StreetlightStatus.functional),
    );
    await h.close();
  });
  test('Missing channels retain cached states and remain visible', () async {
    final h = Harness();
    await h.publish(snapshot(h.now, motion: true, led: true));
    await h.publish(snapshot(h.now, count: 1));
    expect(h.live.lights.length, 4);
    expect(h.live.lights.first.status, StreetlightStatus.functional);
    expect(h.live.lights.last.status, StreetlightStatus.warning);
    expect(h.live.lights.last.statusReason, contains('1 of 4'));
    expect(h.live.lights.last.ledOn, isTrue);
    expect(h.live.lights.last.currentTelemetry, isFalse);
    expect(h.live.alerts.length, 3);
    await h.close();
  });
  test('Corrupt snapshots warn without dropping last-known values', () async {
    final h = Harness();
    await h.publish(snapshot(h.now, led: true));
    await h.publish({'v': 999});
    expect(h.live.lights.length, 4);
    expect(h.live.lights.first.ledOn, isTrue);
    expect(h.live.lights.first.status, StreetlightStatus.warning);
    expect(h.live.lights.first.currentTelemetry, isFalse);
    expect(h.live.alerts.single.title, contains('attention'));
    await h.close();
  });
  test('Command mismatch warns but normal hold is permitted', () async {
    final h = Harness();
    await h.publish(snapshot(h.now, dark: false, led: true));
    expect(h.live.lights.first.status, StreetlightStatus.warning);
    await h.publish(snapshot(h.now, motion: true, led: false));
    expect(h.live.lights.first.status, StreetlightStatus.warning);
    await h.publish(snapshot(h.now, motion: false, led: true));
    expect(h.live.lights.first.status, StreetlightStatus.functional);
    await h.close();
  });
  testWidgets(
    'Missing units have safe details and explicit unknown indicators',
    (tester) async {
      final h = Harness();
      await tester.runAsync(() => h.publish(snapshot(h.now, count: 1)));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MapScreen(live: h.live)),
        ),
      );
      expect(find.text('UNIT #4'), findsOneWidget);
      expect(find.text('Motion: Unknown'), findsNWidgets(3));
      expect(find.text('LED: Unknown'), findsNWidgets(3));
      await tester.tap(find.text('UNIT #4'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Unknown'), findsNWidgets(3));
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.close);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
