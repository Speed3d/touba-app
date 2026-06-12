import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام أنماط النصوص الموحد
///
/// هذا الملف يحتوي على جميع أنماط النصوص المستخدمة في التطبيق
/// بدلاً من تعريف TextStyle في كل شاشة، نستخدم الأنماط من هنا
/// هذا يضمن اتساق الخطوط والأحجام في كل التطبيق
///
/// الاستخدام:
/// Text('Title', style: AppTextStyles.getTitleStyle(context))
/// Text('Body', style: context.bodyTextStyle)
class AppTextStyles {
  AppTextStyles._();

  // ============= Title Styles =============

  // عنوان كبير - يستخدم في رؤوس الشاشات الرئيسية
  // الحجم: 28px، الوزن: Bold
  static TextStyle titleLargeLight = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
    height: 1.2,
    // إضافة ظل للنص لتحسين الرؤية
    shadows: [
      const Shadow(
        color: Color(0x00000000),
        blurRadius: 0,
        offset: Offset(0, 0),
      ),
    ],
  );

  static TextStyle titleLargeDark = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDark,
    height: 1.2,
    shadows: [
      Shadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 2,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // عنوان متوسط - يستخدم في رؤوس الأقسام والبطاقات
  // الحجم: 20px، الوزن: SemiBold
  static TextStyle titleMediumLight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.3,
    shadows: [
      const Shadow(
        color: Color(0x00000000),
        blurRadius: 0,
        offset: Offset(0, 0),
      ),
    ],
  );

  static TextStyle titleMediumDark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
    height: 1.3,
    shadows: [
      Shadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // عنوان صغير - يستخدم في رؤوس القوائم والعناصر الفرعية
  // الحجم: 16px، الوزن: SemiBold
  static TextStyle titleSmallLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.4,
  );

  static TextStyle titleSmallDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
    height: 1.4,
  );

  // ============= Body Styles =============

  // نص الجسم الكبير - للنصوص الرئيسية والوصفات الطويلة
  // الحجم: 16px، الوزن: Regular
  static TextStyle bodyLargeLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle bodyLargeDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryDark,
    height: 1.5,
    letterSpacing: 0.15,
  );

  // نص الجسم المتوسط - للنصوص العادية
  // الحجم: 14px، الوزن: Regular
  static TextStyle bodyMediumLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
    height: 1.5,
    letterSpacing: 0.25,
  );

  static TextStyle bodyMediumDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryDark,
    height: 1.5,
    letterSpacing: 0.25,
  );

  // نص الجسم الصغير - للتفاصيل والنصوص الثانوية
  // الحجم: 12px، الوزن: Regular
  static TextStyle bodySmallLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryLight,
    height: 1.5,
    letterSpacing: 0.4,
  );

  static TextStyle bodySmallDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // ============= Label Styles =============

  // نص التسميات الكبير - للأزرار والعناصر التفاعلية
  // الحجم: 14px، الوزن: SemiBold
  static TextStyle labelLargeLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelLargeDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // نص التسميات المتوسطة
  // الحجم: 12px، الوزن: SemiBold
  static TextStyle labelMediumLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelMediumDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // نص التسميات الصغير - للعلامات والشارات
  // الحجم: 11px، الوزن: Medium
  static TextStyle labelSmallLight = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondaryLight,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmallDark = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondaryDark,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ============= Special Styles =============

  // نص التلميح (Placeholder) - للحقول الفارغة
  // الحجم: 14px، الوزن: Regular، اللون: رمادي فاتح
  static TextStyle hintLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHintLight,
    height: 1.5,
  );

  static TextStyle hintDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHintDark,
    height: 1.5,
  );

  // نص الخطأ - للرسائل الخطأ والتنبيهات
  // الحجم: 12px، الوزن: Medium، اللون: أحمر
  static TextStyle errorLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
  );

  static TextStyle errorDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
  );

  // نص النجاح - للرسائل الإيجابية
  // الحجم: 12px، الوزن: Medium، اللون: أخضر
  static TextStyle successLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
  );

  static TextStyle successDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
  );

  // نص التحذير - للرسائل التحذيرية
  // الحجم: 12px، الوزن: Medium، اللون: كهرماني
  static TextStyle warningLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    height: 1.4,
  );

  static TextStyle warningDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    height: 1.4,
  );

  // ============= Helper Methods =============

  // الحصول على نمط العنوان الكبير حسب الثيم
  static TextStyle getTitleLargeStyle(bool isDark) =>
      isDark ? titleLargeDark : titleLargeLight;

  // الحصول على نمط العنوان المتوسط حسب الثيم
  static TextStyle getTitleMediumStyle(bool isDark) =>
      isDark ? titleMediumDark : titleMediumLight;

  // الحصول على نمط العنوان الصغير حسب الثيم
  static TextStyle getTitleSmallStyle(bool isDark) =>
      isDark ? titleSmallDark : titleSmallLight;

  // الحصول على نمط نص الجسم الكبير حسب الثيم
  static TextStyle getBodyLargeStyle(bool isDark) =>
      isDark ? bodyLargeDark : bodyLargeLight;

  // الحصول على نمط نص الجسم المتوسط حسب الثيم
  static TextStyle getBodyMediumStyle(bool isDark) =>
      isDark ? bodyMediumDark : bodyMediumLight;

  // الحصول على نمط نص الجسم الصغير حسب الثيم
  static TextStyle getBodySmallStyle(bool isDark) =>
      isDark ? bodySmallDark : bodySmallLight;

  // الحصول على نمط التسميات الكبيرة حسب الثيم
  static TextStyle getLabelLargeStyle(bool isDark) =>
      isDark ? labelLargeDark : labelLargeLight;

  // الحصول على نمط التسميات المتوسطة حسب الثيم
  static TextStyle getLabelMediumStyle(bool isDark) =>
      isDark ? labelMediumDark : labelMediumLight;

  // الحصول على نمط التسميات الصغيرة حسب الثيم
  static TextStyle getLabelSmallStyle(bool isDark) =>
      isDark ? labelSmallDark : labelSmallLight;

  // الحصول على نمط النصوص التلميح حسب الثيم
  static TextStyle getHintStyle(bool isDark) => isDark ? hintDark : hintLight;

  // الحصول على نمط النصوص الخطأ
  static TextStyle getErrorStyle(bool isDark) =>
      isDark ? errorDark : errorLight;

  // الحصول على نمط النصوص النجاح
  static TextStyle getSuccessStyle(bool isDark) =>
      isDark ? successDark : successLight;

  // الحصول على نمط النصوص التحذير
  static TextStyle getWarningStyle(bool isDark) =>
      isDark ? warningDark : warningLight;

  // دالة شاملة للحصول على أي نمط نص
  // استخدم: AppTextStyles.getStyleByType('title_large', isDark)
  // الأنواع المتاحة: title_large, title_medium, title_small,
  // body_large, body_medium, body_small, label_large, label_medium, label_small,
  // hint, error, success, warning
  static TextStyle getStyleByType(String styleType, bool isDark) {
    switch (styleType.toLowerCase()) {
      case 'title_large':
        return getTitleLargeStyle(isDark);
      case 'title_medium':
        return getTitleMediumStyle(isDark);
      case 'title_small':
        return getTitleSmallStyle(isDark);
      case 'body_large':
        return getBodyLargeStyle(isDark);
      case 'body_medium':
        return getBodyMediumStyle(isDark);
      case 'body_small':
        return getBodySmallStyle(isDark);
      case 'label_large':
        return getLabelLargeStyle(isDark);
      case 'label_medium':
        return getLabelMediumStyle(isDark);
      case 'label_small':
        return getLabelSmallStyle(isDark);
      case 'hint':
        return getHintStyle(isDark);
      case 'error':
        return getErrorStyle(isDark);
      case 'success':
        return getSuccessStyle(isDark);
      case 'warning':
        return getWarningStyle(isDark);
      default:
        return getBodyMediumStyle(isDark);
    }
  }
}

// امتداد لتسهيل الوصول إلى أنماط النصوص من BuildContext
extension AppTextStylesExtension on BuildContext {
  // هل الثيم الحالي داكن؟
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // نمط العنوان الكبير
  TextStyle get titleLargeStyle => AppTextStyles.getTitleLargeStyle(_isDark);

  // نمط العنوان المتوسط
  TextStyle get titleMediumStyle => AppTextStyles.getTitleMediumStyle(_isDark);

  // نمط العنوان الصغير
  TextStyle get titleSmallStyle => AppTextStyles.getTitleSmallStyle(_isDark);

  // نمط نص الجسم الكبير
  TextStyle get bodyLargeStyle => AppTextStyles.getBodyLargeStyle(_isDark);

  // نمط نص الجسم المتوسط
  TextStyle get bodyMediumStyle => AppTextStyles.getBodyMediumStyle(_isDark);

  // نمط نص الجسم الصغير
  TextStyle get bodySmallStyle => AppTextStyles.getBodySmallStyle(_isDark);

  // نمط التسميات الكبيرة
  TextStyle get labelLargeStyle => AppTextStyles.getLabelLargeStyle(_isDark);

  // نمط التسميات المتوسطة
  TextStyle get labelMediumStyle => AppTextStyles.getLabelMediumStyle(_isDark);

  // نمط التسميات الصغيرة
  TextStyle get labelSmallStyle => AppTextStyles.getLabelSmallStyle(_isDark);

  // نمط النصوص التلميح
  TextStyle get hintStyle => AppTextStyles.getHintStyle(_isDark);

  // نمط النصوص الخطأ
  TextStyle get errorStyle => AppTextStyles.getErrorStyle(_isDark);

  // نمط النصوص النجاح
  TextStyle get successStyle => AppTextStyles.getSuccessStyle(_isDark);

  // نمط النصوص التحذير
  TextStyle get warningStyle => AppTextStyles.getWarningStyle(_isDark);

  // اختصار سريع - نمط الجسم الافتراضي (الأكثر استخداماً)
  TextStyle get defaultTextStyle => bodyMediumStyle;

  // الحصول على أي نمط حسب النوع
  TextStyle getStyleByType(String styleType) =>
      AppTextStyles.getStyleByType(styleType, _isDark);
}
