import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'data/live_controller.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.appId.isEmpty) {
      throw StateError('Android Firebase registration is missing.');
    }
    await Firebase.initializeApp(options: options);
    runApp(const RadiantApp());
  } catch (error) {
    debugPrint('Radiant startup failed: $error');
    runApp(
      MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Radiant could not start. Check the Firebase setup and reopen the app.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RadiantApp extends StatefulWidget {
  const RadiantApp({super.key});
  @override
  State<RadiantApp> createState() => _RadiantAppState();
}

class _RadiantAppState extends State<RadiantApp> {
  ThemeMode _mode = ThemeMode.light;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Radiant',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    darkTheme: AppTheme.darkTheme,
    themeMode: _mode,
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, auth) {
        if (auth.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Cannot check your sign-in. Reopen the app.'),
            ),
          );
        }
        if (auth.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = auth.data;
        if (user == null) {
          return LoginScreen(
            onSignIn: (email, password) async {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
            },
          );
        }
        return _LiveSession(
          key: ValueKey(user.uid),
          email: user.email ?? 'Dashboard account',
          dark: _mode == ThemeMode.dark,
          onToggleDark: (dark) =>
              setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
        );
      },
    ),
  );
}

class _LiveSession extends StatefulWidget {
  final String email;
  final bool dark;
  final ValueChanged<bool> onToggleDark;
  const _LiveSession({
    super.key,
    required this.email,
    required this.dark,
    required this.onToggleDark,
  });
  @override
  State<_LiveSession> createState() => _LiveSessionState();
}

class _LiveSessionState extends State<_LiveSession> {
  late final LiveController live;
  @override
  void initState() {
    super.initState();
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.databaseUrl,
    );
    live = LiveController(
      readings: db
          .ref('gateways/uno-01/latest')
          .onValue
          .map((event) => event.snapshot.value),
      connection: db
          .ref('.info/connected')
          .onValue
          .map((event) => event.snapshot.value),
      serverOffset: db
          .ref('.info/serverTimeOffset')
          .onValue
          .map((event) => event.snapshot.value),
    );
  }

  @override
  void dispose() {
    live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RootNavShell(
    live: live,
    email: widget.email,
    isDarkMode: widget.dark,
    onToggleDarkMode: widget.onToggleDark,
  );
}

class RootNavShell extends StatefulWidget {
  final LiveController live;
  final String email;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  const RootNavShell({
    super.key,
    required this.live,
    required this.email,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });
  @override
  State<RootNavShell> createState() => _RootNavShellState();
}

class _RootNavShellState extends State<RootNavShell> {
  int _selectedIndex = 0;
  void _navigate(int index) => setState(() => _selectedIndex = index);
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.live,
    builder: (context, _) => Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(live: widget.live, onNavigateToTab: _navigate),
          MapScreen(live: widget.live),
          SettingsScreen(
            isDarkMode: widget.isDarkMode,
            onToggleDarkMode: widget.onToggleDarkMode,
            email: widget.email,
            onSignOut: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigate,
        selectedItemColor: AppTheme.primaryMediumCyan,
        unselectedItemColor: Colors.white,
        backgroundColor: AppTheme.primaryDarkBlue,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Streetlight List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    ),
  );
}
