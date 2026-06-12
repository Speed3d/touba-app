import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

///  ثيمات البطاقات — مستخرج من app_theme.dart لسهولة الصيانة
/// لا تغيير في المنطق أو الألوان أو القيم — فقط نقل الكود
class CardThemeBuilder {
  CardThemeBuilder._();

  ///  ثيم البطاقات — الوضع الفاتح
  static CardThemeData buildLight({
    required bool isGlass,
    required double cardRadius,
    required double cardElevation,
  }) {
    return CardThemeData(
      elevation: cardElevation,
      color: isGlass ? AppColors.cardLightGlass : AppColors.cardLightClassic,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: isGlass
              ? AppColors.glassBorderLight
                  .withValues(alpha: DesignTokens.glassBorderOpacityLight)
              : AppColors.cardBorderLightClassic,
          width: isGlass
              ? DesignTokens.glassBorderWidth
              : DesignTokens.classicBorderWidth,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  ///  ثيم البطاقات — الوضع الداكن
  static CardThemeData buildDark({
    required bool isGlass,
    required double cardRadius,
    required double cardElevation,
  }) {
    return CardThemeData(
      elevation: cardElevation,
      color: isGlass ? AppColors.cardDarkGlass : AppColors.cardDarkClassic,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: isGlass
              ? AppColors.glassBorderDark
                  .withValues(alpha: DesignTokens.glassBorderOpacityDark)
              : AppColors.cardBorderDarkClassic,
          width: isGlass
              ? DesignTokens.glassBorderWidth
              : DesignTokens.classicBorderWidth,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  ///  ثيم Dialog — الوضع الفاتح
  static DialogThemeData buildLightDialog({required bool isGlass}) {
    return DialogThemeData(
      backgroundColor: isGlass
          ? AppColors.surfaceLight.withValues(alpha: 0.9)
          : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isGlass ? 20 : 16),
      ),
      elevation: isGlass ? 0 : 8,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
        fontFamily: 'Cairo',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondaryLight,
        fontFamily: 'Cairo',
      ),
    );
  }

  ///  ثيم Dialog — الوضع الداكن
  static DialogThemeData buildDarkDialog({required bool isGlass}) {
    return DialogThemeData(
      backgroundColor: isGlass
          ? AppColors.surfaceDark.withValues(alpha: 0.9)
          : AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isGlass ? 20 : 16),
      ),
      elevation: isGlass ? 0 : 8,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
        fontFamily: 'Cairo',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondaryDark,
        fontFamily: 'Cairo',
      ),
    );
  }

  ///  ثيم البوتوم شيت — الوضع الفاتح
  static BottomSheetThemeData buildLightBottomSheet({required bool isGlass}) {
    return BottomSheetThemeData(
      backgroundColor: isGlass
          ? AppColors.surfaceLight.withValues(alpha: 0.95)
          : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: isGlass
          ? AppColors.surfaceLight.withValues(alpha: 0.95)
          : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isGlass ? 24 : 20),
        ),
      ),
    );
  }

  ///  ثيم البوتوم شيت — الوضع الداكن
  static BottomSheetThemeData buildDarkBottomSheet({required bool isGlass}) {
    return BottomSheetThemeData(
      backgroundColor: isGlass
          ? AppColors.surfaceDark.withValues(alpha: 0.95)
          : AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: isGlass
          ? AppColors.surfaceDark.withValues(alpha: 0.95)
          : AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isGlass ? 24 : 20),
        ),
      ),
    );
  }

  ///  ثيم Drawer — الوضع الفاتح
  static DrawerThemeData buildLightDrawer({required bool isGlass}) {
    return DrawerThemeData(
      backgroundColor: isGlass
          ? AppColors.surfaceLight.withValues(alpha: 0.9)
          : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  ///  ثيم Drawer — الوضع الداكن
  static DrawerThemeData buildDarkDrawer({required bool isGlass}) {
    return DrawerThemeData(
      backgroundColor: isGlass
          ? AppColors.surfaceDark.withValues(alpha: 0.9)
          : AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
