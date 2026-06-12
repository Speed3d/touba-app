import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

///  ثيمات حقول الإدخال — مستخرج من app_theme.dart لسهولة الصيانة
/// لا تغيير في المنطق أو الألوان أو القيم — فقط نقل الكود
class InputThemeBuilder {
  InputThemeBuilder._();

  ///  ثيم حقول الإدخال — الوضع الفاتح
  static InputDecorationTheme buildLight({
    required bool isGlass,
    required double cardRadius,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isGlass
          ? AppColors.cardLightGlass
              .withValues(alpha: DesignTokens.glassOpacityLight)
          : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: BorderSide(
          color: isGlass
              ? AppColors.glassBorderLight.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: BorderSide(
          color: isGlass
              ? AppColors.glassBorderLight.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(
          color: AppColors.primaryLight,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      labelStyle: const TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 14,
        fontFamily: 'Cairo',
      ),
      hintStyle: const TextStyle(
        color: AppColors.textHintLight,
        fontSize: 14,
        fontFamily: 'Cairo',
      ),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 12,
        fontFamily: 'Cairo',
      ),
    );
  }

  ///  ثيم حقول الإدخال — الوضع الداكن
  static InputDecorationTheme buildDark({
    required bool isGlass,
    required double cardRadius,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isGlass
          ? AppColors.cardDarkGlass
              .withValues(alpha: DesignTokens.glassOpacityDark)
          : AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: BorderSide(
          color: isGlass
              ? AppColors.glassBorderDark.withValues(alpha: 0.2)
              : AppColors.borderDark,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: BorderSide(
          color: isGlass
              ? AppColors.glassBorderDark.withValues(alpha: 0.2)
              : AppColors.borderDark,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(
          color: AppColors.primaryDark,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      labelStyle: const TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 14,
        fontFamily: 'Cairo',
      ),
      hintStyle: const TextStyle(
        color: AppColors.textHintDark,
        fontSize: 14,
        fontFamily: 'Cairo',
      ),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 12,
        fontFamily: 'Cairo',
      ),
    );
  }
}
