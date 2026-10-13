import 'package:flutter/material.dart';

import '../../models/streetlight.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class StreetlightDetailScreen extends StatelessWidget {
  final Streetlight light;

  const StreetlightDetailScreen({super.key, required this.light});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(light.id)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  light.location,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusBadge(status: light.status),
              ],
            ),
            const SizedBox(height: 20),
            _InfoTile(
              icon: Icons.wb_sunny_outlined,
              label: 'Brightness Output',
              value: '${light.brightnessPercent}%',
            ),
            _InfoTile(
              icon: Icons.bolt_outlined,
              label: 'Energy Today',
              value: '${light.energyTodayKwh} kWh',
            ),
            _InfoTile(
              icon: Icons.directions_walk,
              label: 'Motion Detected',
              value: light.motionDetected ? 'Yes' : 'No',
            ),
            _InfoTile(
              icon: Icons.build_outlined,
              label: 'Last Maintenance',
              value: light.lastMaintenance,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: light.tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: AppTheme.summaryBg(
                        context,
                      ), // Updated for dark mode[cite: 3]
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryMediumCyan),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
