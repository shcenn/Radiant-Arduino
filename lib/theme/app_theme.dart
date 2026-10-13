import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryMediumCyan = Color(0xFF2295C7);
  static const Color primaryDarkBlue = Color(0xFF123461);
  static const Color lightBlueBg = Color(0xFFC9DEF3);
  static const Color statusGreen = Color(0xFF43A047);
  static const Color statusYellow = Color(0xFFFBC02D);
  static const Color statusRed = Color(0xFFE53935);
  static const Color cardBorder = Color(0xFFE0E0E0);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Background for cards, alert rows, and count tiles.
  static Color cardBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B232B) : Colors.white;

  /// Background for the blue summary card and chips.
  static Color summaryBg(BuildContext context) =>
      isDark(context) ? primaryDarkBlue : lightBlueBg;

  static Color cardBorderColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF2E3A46) : cardBorder;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryMediumCyan,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMediumCyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMediumCyan,
          side: const BorderSide(color: primaryMediumCyan),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryMediumCyan,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMediumCyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.lightBlueAccent,
          side: const BorderSide(color: Colors.lightBlueAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
