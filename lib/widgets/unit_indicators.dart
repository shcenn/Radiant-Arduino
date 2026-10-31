import 'package:flutter/material.dart';

import '../models/streetlight.dart';

class UnitIndicators extends StatelessWidget {
  final Streetlight light;
  const UnitIndicators({super.key, required this.light});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      _Indicator(
        icon: Icons.directions_walk,
        label: light.motionDetected == null
            ? 'Motion: Unknown'
            : light.motionDetected!
            ? 'Motion: Detected'
            : 'Motion: None',
        active: light.motionDetected,
        stale: !light.currentTelemetry,
      ),
      _Indicator(
        icon: Icons.lightbulb_outline,
        label: light.ledOn == null
            ? 'LED: Unknown'
            : light.ledOn!
            ? 'LED: ON'
            : 'LED: OFF',
        active: light.ledOn,
        stale: !light.currentTelemetry,
      ),
      if (light.lastObservedAt != null && !light.currentTelemetry)
        const Text(
          'Last reported',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
    ],
  );
}

class _Indicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? active;
  final bool stale;
  const _Indicator({
    required this.icon,
    required this.label,
    this.active,
    required this.stale,
  });
  @override
  Widget build(BuildContext context) {
    final color = stale || active == null
        ? Colors.grey
        : active!
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
