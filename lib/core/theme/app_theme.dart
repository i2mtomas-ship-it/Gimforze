import 'package:flutter/material.dart';

class AppTheme {
  // Identidad visual Gimforze: oscuro, deportivo, juvenil y limpio.
  static const primary = Color(0xFF9B5CFF);
  static const primaryBright = Color(0xFFB47CFF);
  static const secondary = Color(0xFF4DE1C1);
  static const highlight = Color(0xFFFF6B9D);
  static const ink = Color(0xFF0B0D14);
  static const background = Color(0xFF090B11);
  static const surface = Color(0xFF111520);
  static const surface2 = Color(0xFF171B28);
  static const text = Color(0xFFF7F7FB);
  static const muted = Color(0xFF9AA0B2);
  static const softIndigo = Color(0xFF211B35);
  static const softMint = Color(0xFF122C29);
  static const softCoral = Color(0xFF321B27);

  static ThemeData get light => dark;

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: ink,
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface2,
      outline: const Color(0xFF2A3040),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'sans',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      }),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: text, fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.6),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: text, fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: -1.0),
        headlineSmall: TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.35),
        bodyMedium: TextStyle(color: muted, fontSize: 14, height: 1.35),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF10131D),
        indicatorColor: primary.withValues(alpha: .22),
        elevation: 0,
        height: 76,
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 23)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shadowColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFF242A39))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2A3040))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.5)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: Color(0xFF303748)),
          foregroundColor: text,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary, foregroundColor: Colors.white, elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(17))),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: softIndigo, selectedColor: Color(0x3333C9FF), side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: text),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF252B39), space: 1),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
