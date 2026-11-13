import 'package:flutter/material.dart';

/// Цвет-акцент, который можно выбрать в профиле.
class AccentOption {
  final String name;
  final Color color;
  const AccentOption(this.name, this.color);
}

const accentOptions = [
  AccentOption('Коралл', Color(0xFFFF6B57)),
  AccentOption('Изумруд', Color(0xFF10A37F)),
  AccentOption('Фиолет', Color(0xFF8B5CF6)),
  AccentOption('Небо', Color(0xFF0EA5E9)),
  AccentOption('Розовый', Color(0xFFEC4899)),
];

// Тёмно-синяя палитра. Весь текст белый.
const Color bgColor = Color(0xFF0A0F1F);
const Color surfaceColor = Color(0xFF141B2F);
const Color surfaceHigh = Color(0xFF1E2744);

// Цвета статусов (стол, бронь, заказ).
const Color freeColor = Color(0xFF22C55E);
const Color busyColor = Color(0xFFEF4444);
const Color reservedColor = Color(0xFFF59E0B);
const Color skyColor = Color(0xFF38BDF8);

/// Градиент для заметных карточек на основе акцентного цвета.
LinearGradient accentGradient(Color accent) {
  final hsl = HSLColor.fromColor(accent);
  final shifted = hsl
      .withHue((hsl.hue + 28) % 360)
      .withLightness((hsl.lightness * 0.8).clamp(0.0, 1.0))
      .toColor();
  return LinearGradient(
    colors: [accent, shifted],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme(Color accent) {
  final scheme = ColorScheme.dark(
    primary: accent,
    onPrimary: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    surface: surfaceColor,
    onSurface: Colors.white,
    surfaceContainer: surfaceColor,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHigh,
    error: busyColor,
    onError: Colors.white,
    outline: Colors.white38,
  );

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: bgColor,
    textTheme: ThemeData.dark()
        .textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: border(Colors.white12),
      enabledBorder: border(Colors.white12),
      focusedBorder: border(accent, 1.6),
      errorBorder: border(busyColor),
      focusedErrorBorder: border(busyColor, 1.6),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: accent,
      height: 68,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: Colors.white),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: Colors.white),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      selectedColor: accent,
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      checkmarkColor: Colors.white,
      side: const BorderSide(color: Colors.white12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceHigh,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Colors.white12),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accent
            : Colors.white24,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? accent : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Colors.white54, width: 1.5),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white,
      textColor: Colors.white,
    ),
  );
}
