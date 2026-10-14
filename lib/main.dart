import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(const RadiantApp());
}

class RadiantApp extends StatefulWidget {
  const RadiantApp({super.key});

  @override
  State<RadiantApp> createState() => _RadiantAppState();
}

class _RadiantAppState extends State<RadiantApp> {
  ThemeMode _themeMode = ThemeMode.light;

  /// The signed-in username, or null when signed out.
  String? _user;

  void _toggleDarkMode(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _login(String username) => setState(() => _user = username);

  void _logout() => setState(() => _user = null);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radiant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      // Signed out -> login screen. Signed in -> the normal tabbed app.
      // Logging out discards RootNavShell, so the next login starts on Home.
      home: _user == null
          ? LoginScreen(onLogin: _login)
          : RootNavShell(
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleDarkMode: _toggleDarkMode,
              username: _user!,
              onLogout: _logout,
            ),
    );
  }
}

class RootNavShell extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final String username;
  final VoidCallback onLogout;

  const RootNavShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.username,
    required this.onLogout,
  });

  @override
  State<RootNavShell> createState() => _RootNavShellState();
}

class _RootNavShellState extends State<RootNavShell> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const MapScreen(),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
        username: widget.username,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppTheme.primaryMediumCyan,
        unselectedItemColor: Colors.white,
        backgroundColor: AppTheme.primaryDarkBlue,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}