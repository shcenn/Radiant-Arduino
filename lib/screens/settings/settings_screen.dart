import 'package:flutter/material.dart';

/// Settings tab.
///
/// Dark Mode and Log out are wired to real app state (passed down from
/// the app root). Notification/monitoring toggles below are mock UI state
/// local to this screen - they look and behave like real switches for the
/// prototype demo, but don't persist or connect to a backend.
///
/// Account: shows who is signed in and lets them log out. Sign-in uses
/// hard-coded demo accounts (see AuthService); account creation and
/// password recovery are out of scope for this project.
class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final String username;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.username,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock-only state - not wired to anything real.
  bool _notificationsEnabled = true;
  bool _criticalAlerts = true;
  bool _maintenanceAlerts = true;
  bool _dailyEnergySummary = false;
  bool _autoRefresh = true;
  String _refreshInterval = '1 min';
  String _defaultMapView = 'All Units';

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to view the traffic lights.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          const _SectionHeader('Account'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(widget.username),
            subtitle: const Text('Signed in'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: errorColor),
            title: Text('Log out', style: TextStyle(color: errorColor)),
            onTap: _confirmLogout,
          ),

          const _SectionHeader('Appearance'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: widget.isDarkMode,
            onChanged: widget.onToggleDarkMode,
          ),

          const _SectionHeader('Notifications'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.warning_amber_outlined),
            title: const Text('Critical Failure Alerts'),
            value: _criticalAlerts,
            onChanged: _notificationsEnabled
                ? (v) => setState(() => _criticalAlerts = v)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.build_outlined),
            title: const Text('Maintenance Alerts'),
            value: _maintenanceAlerts,
            onChanged: _notificationsEnabled
                ? (v) => setState(() => _maintenanceAlerts = v)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.bolt_outlined),
            title: const Text('Daily Energy Summary'),
            value: _dailyEnergySummary,
            onChanged: _notificationsEnabled
                ? (v) => setState(() => _dailyEnergySummary = v)
                : null,
          ),

          const _SectionHeader('Monitoring'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.sync),
            title: const Text('Auto-refresh Data'),
            value: _autoRefresh,
            onChanged: (v) => setState(() => _autoRefresh = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Refresh Interval'),
            trailing: DropdownButton<String>(
              value: _refreshInterval,
              underline: const SizedBox.shrink(),
              items: const [
                '30 sec',
                '1 min',
                '5 min',
                '15 min',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: _autoRefresh
                  ? (v) => setState(() => _refreshInterval = v!)
                  : null,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.map_outlined),
            title: const Text('Default Map View'),
            trailing: DropdownButton<String>(
              value: _defaultMapView,
              underline: const SizedBox.shrink(),
              items: const [
                'All Units',
                'Warnings Only',
                'Failures Only',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _defaultMapView = v!),
            ),
          ),

          const _SectionHeader('About'),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline),
            title: Text('About Radiant'),
            subtitle: Text(
              'Arduino-based adaptive streetlight monitoring prototype, '
              'ITE 013 — Application Development and Emerging Technologies.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.help_outline),
            title: Text('Help & Support'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.numbers_outlined),
            title: Text('Version'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}