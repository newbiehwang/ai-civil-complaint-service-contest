import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'krds_tokens.dart';

class KrdsTheme {
  const KrdsTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard GOV',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    final textTheme = base.textTheme.copyWith(
      bodyLarge: const TextStyle(
        fontSize: 17,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textMain,
      ),
      bodyMedium: const TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textMain,
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
      titleLarge: const TextStyle(
        fontSize: 24,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
      headlineSmall: const TextStyle(
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 17,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          textStyle: const TextStyle(
            fontSize: 17,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KrdsTokens.space12,
          vertical: KrdsTokens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
        ),
      ),
    );
  }
}
