// Sistema de diseño SIAA — T-PLT-03.2, T-PLT-03.3
// Paleta de colores, tipografía y tokens de diseño del sistema.
// SRS §9.3: colores semánticos reservados a estados de asistencia.
import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

// ─────────────────────────────────────────────────────────────
// TIPOGRAFÍA
// ─────────────────────────────────────────────────────────────

class SIAATypography {
  SIAATypography._();

  static const String fontFamily = 'Inter';

  // Escalas de texto (4 escalas del sistema de diseño)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );
}

// ─────────────────────────────────────────────────────────────
// ESPACIADO (Retícula de 8px — T-PLT-03.2)
// ─────────────────────────────────────────────────────────────

class SIAASpacing {
  SIAASpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Bordes redondeados
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(100));
}

// ─────────────────────────────────────────────────────────────
// TEMAS — T-PLT-03.3
// Contraste mínimo verificado: ≥ 4.5:1 (RNF-USA-003)
// ─────────────────────────────────────────────────────────────

class SIAATheme {
  SIAATheme._();

  // ─── Tema Claro ────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: SIAAColors.primary500,
          onPrimary: Colors.white,
          primaryContainer: SIAAColors.primary50,
          onPrimaryContainer: SIAAColors.primary900,
          secondary: SIAAColors.accent,
          onSecondary: Colors.white,
          surface: SIAAColors.surfaceLight,
          onSurface: SIAAColors.neutral900,
          background: SIAAColors.backgroundLight,
          onBackground: SIAAColors.neutral800,
          error: SIAAColors.asistenciaAusente,
          onError: Colors.white,
          outline: SIAAColors.neutral300,
        ),
        fontFamily: SIAATypography.fontFamily,
        textTheme: _textTheme(SIAAColors.neutral900),
        appBarTheme: const AppBarTheme(
          backgroundColor: SIAAColors.surfaceLight,
          foregroundColor: SIAAColors.neutral900,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        inputDecorationTheme: _inputTheme(light: true),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(light: true),
        cardTheme: const CardThemeData(
          color: SIAAColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: SIAASpacing.radiusMd,
            side: BorderSide(color: SIAAColors.neutral200),
          ),
        ),
        dividerColor: SIAAColors.neutral200,
        scaffoldBackgroundColor: SIAAColors.backgroundLight,
      );

  // ─── Tema Oscuro ───────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: SIAAColors.primary400,
          onPrimary: SIAAColors.primary900,
          primaryContainer: SIAAColors.primary800,
          onPrimaryContainer: SIAAColors.primary100,
          secondary: Color(0xFFA78BFA),
          onSecondary: SIAAColors.neutral900,
          surface: SIAAColors.surfaceDark,
          onSurface: SIAAColors.neutral100,
          background: SIAAColors.backgroundDark,
          onBackground: SIAAColors.neutral200,
          error: Color(0xFFF87171),
          onError: SIAAColors.neutral900,
          outline: SIAAColors.neutral700,
        ),
        fontFamily: SIAATypography.fontFamily,
        textTheme: _textTheme(SIAAColors.neutral100),
        appBarTheme: const AppBarTheme(
          backgroundColor: SIAAColors.surfaceDark,
          foregroundColor: SIAAColors.neutral100,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        inputDecorationTheme: _inputTheme(light: false),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(light: false),
        cardTheme: const CardThemeData(
          color: SIAAColors.surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: SIAASpacing.radiusMd,
            side: BorderSide(color: SIAAColors.neutral700),
          ),
        ),
        dividerColor: SIAAColors.neutral700,
        scaffoldBackgroundColor: SIAAColors.backgroundDark,
      );

  // ─── Helpers de tema ───────────────────────────────────────

  static TextTheme _textTheme(Color baseColor) => TextTheme(
        displayLarge: SIAATypography.displayLarge.copyWith(color: baseColor),
        headlineMedium:
            SIAATypography.headlineMedium.copyWith(color: baseColor),
        titleLarge: SIAATypography.titleLarge.copyWith(color: baseColor),
        bodyLarge: SIAATypography.bodyLarge.copyWith(color: baseColor),
        bodyMedium: SIAATypography.bodyMedium.copyWith(color: baseColor),
        labelLarge: SIAATypography.labelLarge.copyWith(color: baseColor),
        labelSmall: SIAATypography.labelSmall.copyWith(color: baseColor),
      );

  static InputDecorationTheme _inputTheme({required bool light}) {
    final border = OutlineInputBorder(
      borderRadius: SIAASpacing.radiusSm,
      borderSide: BorderSide(
        color: light ? SIAAColors.neutral300 : SIAAColors.neutral600,
      ),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: light ? SIAAColors.neutral50 : SIAAColors.neutral800,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: SIAASpacing.radiusSm,
        borderSide: const BorderSide(color: SIAAColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: SIAASpacing.radiusSm,
        borderSide: const BorderSide(color: SIAAColors.asistenciaAusente),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.md,
        vertical: SIAASpacing.md,
      ),
      hintStyle: TextStyle(
        fontFamily: SIAATypography.fontFamily,
        color: light ? SIAAColors.neutral400 : SIAAColors.neutral500,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SIAAColors.primary500,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52), // ≥ 44px táctil (RNF-USA-003)
          shape:
              const RoundedRectangleBorder(borderRadius: SIAASpacing.radiusSm),
          textStyle: SIAATypography.labelLarge,
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({required bool light}) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SIAAColors.primary500,
          minimumSize: const Size.fromHeight(52),
          shape:
              const RoundedRectangleBorder(borderRadius: SIAASpacing.radiusSm),
          side: const BorderSide(color: SIAAColors.primary500),
          textStyle: SIAATypography.labelLarge,
        ),
      );
}
