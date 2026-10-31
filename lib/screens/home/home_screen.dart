import 'package:flutter/material.dart';

import '../../data/live_controller.dart';
import '../../models/streetlight.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

/// The Home tab: summary card + recent alerts feed.
///
/// [onNavigateToTab] lets this screen switch the bottom nav tab
/// (0 = Home, 1 = Map, 2 = Settings) â€” passed down from RootNavShell.
class HomeScreen extends StatelessWidget {
  final LiveController live;
  final void Function(int tabIndex) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.live,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final lights = live.lights;
    final total = lights.length;
    final functional = lights
        .where((l) => l.status == StreetlightStatus.functional)
        .length;
    final warning = lights
        .where((l) => l.status == StreetlightStatus.warning)
        .length;
    final offline = lights
        .where((l) => l.status == StreetlightStatus.offline)
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
              color: AppTheme.summaryBg(
                context,
              ), // Uses summary background helper
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total ${total == 1 ? "streetlight" : "streetlights"} configured',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface, // Added explicit text color
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
                    _StatChip(
                      count: offline,
                      status: StreetlightStatus.offline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => onNavigateToTab(1), // Map tab
            icon: const Icon(Icons.map_outlined),
            label: const Text('View Streetlight List'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Live gateway status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        live.online
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        color: live.online ? AppTheme.statusGreen : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          live.connectionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Last synced: ${live.lastSynced}'),
                  const SizedBox(height: 4),
                  Text('Sensor observation: ${live.lastSeen}'),
                  if (live.reading != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${live.online ? "Ambient light" : "Last reported ambient light"}: ${live.reading!.dark ? "Dark" : "Daylight"}',
                    ),
                  ],
                  if (live.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        live.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Current alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (live.alerts.isEmpty)
            const ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text('No monitoring alerts'),
              subtitle: Text('All configured channels are reporting normally.'),
            ),
          for (final alert in live.alerts)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: alert.status.color,
                ),
                title: Text(alert.title),
                subtitle: Text(alert.detail),
                onTap: () => onNavigateToTab(1),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
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
          color: AppTheme.cardBg(
            context,
          ), // Updated to use explicit cardBg helper
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
