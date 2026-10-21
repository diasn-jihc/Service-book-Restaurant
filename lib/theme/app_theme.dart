import 'package:flutter/material.dart';

class AccentOption {
  final String name;
  final Color color;
  const AccentOption(this.name, this.color);
}

const accentOptions = [
  AccentOption('Бордовый', Color(0xFFA4262C)),
  AccentOption('Золотой', Color(0xFFB8860B)),
  AccentOption('Изумрудный', Color(0xFF2E7D5B)),
  AccentOption('Апельсиновый', Color(0xFFC0561B)),
  AccentOption('Синий', Color(0xFF2F6DB5)),
];

const Color appBackground = Color(0xFF1B1412);
const Color cardColor = Color(0xFF2B211D);
const Color warningCardColor = Color(0xFF6E2A26);

ThemeData buildTheme(Color accent) {
  final scheme = ColorScheme.dark(
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: accent,
    onPrimaryContainer: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    secondaryContainer: accent,
    onSecondaryContainer: Colors.white,
    error: const Color(0xFFE5534B),
    onError: Colors.white,
    errorContainer: warningCardColor,
    onErrorContainer: Colors.white,
    surface: cardColor,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.white,
    outline: Colors.white54,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: appBackground,
    textTheme: ThemeData.dark()
        .textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: appBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(color: Colors.white24),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: cardColor,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: cardColor,
      labelStyle: TextStyle(color: Colors.white),
      checkmarkColor: Colors.white,
      side: BorderSide(color: Colors.white24),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
  );
}
