import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final String email;
  final Future<void> Function() onSignOut;
  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.email,
    required this.onSignOut,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Dark Mode'),
          value: widget.isDarkMode,
          onChanged: widget.onToggleDarkMode,
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: const Text('Signed in as'),
          subtitle: Text(widget.email),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: const Icon(Icons.logout),
          label: Text(_busy ? 'Signing out...' : 'Sign out'),
        ),
        const SizedBox(height: 24),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.sync),
          title: Text('Live monitoring'),
          subtitle: Text(
            'Four units stay listed. Readings delayed over 15 seconds show Warning; telemetry expires after 30 seconds. Missing channels and invalid data also raise alerts.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline),
          title: Text('About Radiant'),
          subtitle: Text(
            'Arduino streetlight monitoring prototype. The controller operates locally; the app displays its reported states.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Version'),
          trailing: Text('1.0.0'),
        ),
      ],
    ),
  );
}
