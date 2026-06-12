import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ثيمات الأزرار — مستخرج من app_theme.dart لسهولة الصيانة
/// لا تغيير في المنطق أو الألوان أو القيم — فقط نقل الكود
class ButtonThemeBuilder {
  ButtonThemeBuilder._();

  // ================== الوضع الفاتح ==================

  /// ثيم الأزرار المرتفعة — فاتح
  static ElevatedButtonThemeData buildLightElevated({
    required bool isGlass,
    required double buttonRadius,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: isGlass ? 0 : 2,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.borderLight,
        disabledForegroundColor: AppColors.textHintLight,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius + 12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  /// ثيم الأزرار المحددة — فاتح
  static OutlinedButtonThemeData buildLightOutlined({
    required bool isGlass,
    required double buttonRadius,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        backgroundColor: isGlass ? Colors.transparent : Colors.white,
        minimumSize: const Size(0, 48),
        side: const BorderSide(
          color: AppColors.primaryLight,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius + 12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  /// ثيم أزرار النص — فاتح
  static TextButtonThemeData buildLightText() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  // ================== الوضع الداكن ==================

  /// ثيم الأزرار المرتفعة — داكن
  static ElevatedButtonThemeData buildDarkElevated({
    required bool isGlass,
    required double buttonRadius,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: isGlass ? 0 : 2,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.backgroundDark,
        disabledBackgroundColor: AppColors.borderDark,
        disabledForegroundColor: AppColors.textHintDark,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius + 12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  /// ثيم الأزرار المحددة — داكن
  static OutlinedButtonThemeData buildDarkOutlined({
    required double buttonRadius,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(0, 48),
        side: const BorderSide(
          color: AppColors.primaryDark,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius + 12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  /// ثيم أزرار النص — داكن
  static TextButtonThemeData buildDarkText() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
