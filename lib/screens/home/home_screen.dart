import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/streetlight.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/alert_card.dart';

/// The Home tab: summary card + recent alerts feed.
///
/// [onNavigateToTab] lets this screen switch the bottom nav tab
/// (0 = Home, 1 = Map, 2 = Settings) — passed down from RootNavShell.
class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const HomeScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final lights = MockData.streetlights;
    final alerts = MockData.alerts;
    final total = lights.length;
    final functional = lights
        .where((l) => l.status == StreetlightStatus.functional)
        .length;
    final warning = lights
        .where((l) => l.status == StreetlightStatus.warning)
        .length;
    final failed = lights
        .where((l) => l.status == StreetlightStatus.failed)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Radiant',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Municipal streetlight monitoring',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.summaryBg(context), // Uses summary background helper[cite: 7]
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total streetlights monitored',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface, // Added explicit text color[cite: 7]
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(
                      count: functional,
                      status: StreetlightStatus.functional,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      count: warning,
                      status: StreetlightStatus.warning,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(count: failed, status: StreetlightStatus.failed),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => onNavigateToTab(1), // Map tab
            icon: const Icon(Icons.map_outlined),
            label: const Text('View All Streetlights'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Recent Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...alerts.map((a) => AlertCard(alert: a)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final StreetlightStatus status;

  const _StatChip({required this.count, required this.status});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context), // Updated to use explicit cardBg helper[cite: 5, 7]
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
            const SizedBox(height: 2),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}