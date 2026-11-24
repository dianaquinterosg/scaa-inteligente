import 'package:flutter/material.dart';

abstract final class ScaaLayout {
  static const small = 8.0;
  static const gap = 16.0;
  static const section = 24.0;
  static const radius = 16.0;
  static const touch = 48.0;
  static const formWidth = 760.0;
  static const contentWidth = 1000.0;
  static const twoColumns = 680.0;
  static const routineStepWide = 216.0;
  static const routineStepNarrow = 184.0;
  static const routinePicture = 140.0;
}

abstract final class ScaaTheme {
  static const primary = Color(0xFF195CA3);
  static const background = Color(0xFFF0F6FC);
  static const confirm = Color(0xFF1C6C3D);
  static const confirmBackground = Color(0xFFE1F4E8);
  static const onConfirmBackground = Color(0xFF133F27);

  static final light = _build();

  static ThemeData _build() {
    final colors = ColorScheme.fromSeed(
      seedColor: primary,
      surface: Colors.white,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDFEEFD),
      onPrimaryContainer: const Color(0xFF102F53),
      outline: const Color(0xFF607992),
      outlineVariant: const Color(0xFFD3E1EF),
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ScaaLayout.radius)),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: colors.outlineVariant)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(ScaaLayout.small)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(ScaaLayout.small),
          ),
          borderSide: BorderSide(color: colors.outline),
        ),
        helperMaxLines: 3,
        errorMaxLines: 4,
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(ScaaLayout.touch)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(ScaaLayout.touch, ScaaLayout.touch),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(ScaaLayout.touch, ScaaLayout.touch),
          shape: shape,
        ),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
