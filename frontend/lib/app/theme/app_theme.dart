import 'package:flutter/material.dart';
import 'package:university_messenger/app/theme/app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static const _blue = Color(0xFF1769AA);
  static const _navy = Color(0xFF153B61);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: brightness,
          surface: isDark ? const Color(0xFF111A23) : const Color(0xFFF8FAFD),
        ).copyWith(
          primary: isDark ? const Color(0xFF70BAF2) : _blue,
          onPrimary: isDark ? const Color(0xFF052A44) : Colors.white,
          secondary: isDark ? const Color(0xFFADCBE5) : _navy,
          onSecondary: isDark ? const Color(0xFF17324A) : Colors.white,
          error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
          surfaceContainerLow: isDark
              ? const Color(0xFF16212C)
              : const Color(0xFFFFFFFF),
          surfaceContainerHighest: isDark
              ? const Color(0xFF26323E)
              : const Color(0xFFE8EEF5),
          outlineVariant: isDark
              ? const Color(0xFF3A4855)
              : const Color(0xFFD7E0E9),
        );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.35,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    return base.copyWith(
      textTheme: textTheme,
      extensions: [
        AppTokens(
          heroBlue: isDark ? const Color(0xFF0D4775) : const Color(0xFF1769AA),
          navy: isDark ? const Color(0xFF8ABBE0) : _navy,
          success: isDark ? const Color(0xFF72D6A1) : const Color(0xFF16885A),
          warning: isDark ? const Color(0xFFFFD18A) : const Color(0xFF9A5B00),
          infoSurface: isDark
              ? const Color(0xFF173247)
              : const Color(0xFFE7F3FC),
          radius: 16,
          pagePadding: 24,
        ),
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
