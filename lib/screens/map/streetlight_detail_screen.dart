import 'package:flutter/material.dart';

import '../../data/live_controller.dart';
import '../../widgets/status_badge.dart';

class StreetlightDetailScreen extends StatelessWidget {
  final LiveController live;
  final int index;
  const StreetlightDetailScreen({
    super.key,
    required this.live,
    required this.index,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: live,
    builder: (context, _) {
      final lights = live.lights;
      if (index >= lights.length) {
        return Scaffold(
          appBar: AppBar(title: const Text('Streetlight')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                live.error ?? 'This unit is no longer in the gateway reading.',
              ),
            ),
          ),
        );
      }
      final light = lights[index];
      final prefix = light.currentTelemetry ? '' : 'Last reported: ';
      return Scaffold(
        appBar: AppBar(title: Text(light.id)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  light.location,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusBadge(status: light.status),
              ],
            ),
            const SizedBox(height: 20),
            Text(light.statusReason),
            const SizedBox(height: 8),
            Text('Last synced: ${live.lastSynced}'),
            Text(
              light.lastObservedAt == null
                  ? 'Unit observation: None received'
                  : 'Unit observation: ${live.serverNow.difference(light.lastObservedAt!).inSeconds.clamp(0, 999999)} seconds ago',
            ),
            const SizedBox(height: 16),
            _Value(
              label: '${prefix}LED command',
              value: light.ledOn == null
                  ? 'Unknown'
                  : light.ledOn!
                  ? 'ON'
                  : 'OFF',
              icon: Icons.lightbulb_outline,
            ),
            _Value(
              label: '${prefix}Motion detected',
              value: light.motionDetected == null
                  ? 'Unknown'
                  : light.motionDetected!
                  ? 'Yes'
                  : 'No',
              icon: Icons.directions_walk,
            ),
            _Value(
              label: '${prefix}Ambient light',
              value: light.dark == null
                  ? 'Unknown'
                  : light.dark!
                  ? 'Dark'
                  : 'Daylight',
              icon: Icons.wb_sunny_outlined,
            ),
            const _Value(
              label: 'Energy use',
              value: 'Not measured',
              icon: Icons.bolt_outlined,
            ),
            const _Value(
              label: 'Bulb health',
              value: 'Not measured',
              icon: Icons.build_outlined,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: light.tags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'The LED command is the output requested by the Arduino. It does not confirm actual light output.',
            ),
            if (live.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  live.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _Value extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Value({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}
