import 'package:flutter/material.dart';

const brandOrange = Color(0xFFEF9B0F);
const brandCharcoal = Color(0xFF24231F);

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final surface = dark ? const Color(0xFF171715) : const Color(0xFFF7F5F0);
  final card = dark ? const Color(0xFF242420) : Colors.white;
  final foreground = dark ? const Color(0xFFF6F3EA) : brandCharcoal;
  final muted = dark ? const Color(0xFFC1BDB1) : const Color(0xFF686358);
  final colors =
      ColorScheme.fromSeed(
        seedColor: brandOrange,
        brightness: brightness,
      ).copyWith(
        primary: dark ? brandOrange : const Color(0xFF865000),
        onPrimary: dark ? brandCharcoal : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF4A3718)
            : const Color(0xFFFFE4B0),
        onPrimaryContainer: dark
            ? const Color(0xFFFFE4B0)
            : const Color(0xFF523100),
        secondary: dark ? const Color(0xFFB5C9AB) : const Color(0xFF46613D),
        surface: surface,
        onSurface: foreground,
        onSurfaceVariant: muted,
        surfaceContainerLow: card,
        surfaceContainerHighest: dark
            ? const Color(0xFF36352F)
            : const Color(0xFFECE8DF),
        outline: dark ? const Color(0xFF8C877A) : const Color(0xFF80796B),
        outlineVariant: dark
            ? const Color(0xFF45433B)
            : const Color(0xFFDFD9CC),
      );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'RunSans',
    colorScheme: colors,
  );
  return base.copyWith(
    scaffoldBackgroundColor: surface,
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: TextStyle(
            fontSize: 40,
            height: 1.08,
            letterSpacing: -1.5,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            height: 1.15,
            letterSpacing: -.7,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: muted),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: muted),
        )
        .apply(fontFamily: 'RunSans'),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: foreground,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'RunSans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 32),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: brandCharcoal,
        minimumSize: const Size(0, 56),
        textStyle: const TextStyle(
          fontFamily: 'RunSans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(0, 56),
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      indicatorColor: colors.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'RunSans',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color: foreground,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: card,
      side: BorderSide(color: colors.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: brandOrange,
      linearTrackColor: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
