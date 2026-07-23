import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand = Color(0xFF3182F6);
  static const brandPressed = Color(0xFF1B64DA);
  static const brandWeak = Color(0xFFEAF3FF);
  static const brandNavy = Color(0xFF123A63);
  static const brandNavyWeak = Color(0xFFEAF0F6);
  static const ocean = Color(0xFF0B8FA3);
  static const oceanWeak = Color(0xFFE7F6F8);
  static const textPrimary = Color(0xFF191F28);
  static const textSecondary = Color(0xFF4E5968);
  static const textTertiary = Color(0xFF8B95A1);
  static const line = Color(0xFFE5E8EB);
  static const surface = Colors.white;
  static const surfaceSecondary = Color(0xFFF2F4F6);
  static const surfaceWeak = Color(0xFFF9FAFB);
  static const success = Color(0xFF00A86B);
  static const successWeak = Color(0xFFE8F8F1);
  static const warning = Color(0xFFFF8A3D);
  static const warningWeak = Color(0xFFFFF2E8);
  static const danger = Color(0xFFF04452);
  static const dangerWeak = Color(0xFFFFECEE);
  static const mapGreen = Color(0xFFDCEEDB);
  static const mapBlue = Color(0xFFDCECF8);
}

abstract final class AppTheme {
  static ThemeData get light {
    const baseText = TextStyle(
      color: AppColors.textPrimary,
      fontFamilyFallback: [
        'Pretendard',
        'Apple SD Gothic Neo',
        'Noto Sans KR',
        'Roboto',
      ],
      height: 1.45,
      letterSpacing: -0.25,
    );

    final textTheme = TextTheme(
      displaySmall: baseText.copyWith(
        fontSize: 32,
        height: 1.22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineLarge: baseText.copyWith(
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: baseText.copyWith(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: baseText.copyWith(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
      ),
      titleLarge: baseText.copyWith(
        fontSize: 20,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseText.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: baseText.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: baseText.copyWith(fontSize: 17, height: 1.5),
      bodyMedium: baseText.copyWith(fontSize: 15, height: 1.5),
      bodySmall: baseText.copyWith(
        fontSize: 13,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      labelLarge: baseText.copyWith(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseText.copyWith(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseText.copyWith(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surface,
      canvasColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
        primary: AppColors.brand,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        selectedColor: AppColors.brandWeak,
        disabledColor: AppColors.surfaceSecondary,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }
}
