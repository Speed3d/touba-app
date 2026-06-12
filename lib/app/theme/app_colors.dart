import 'package:flutter/material.dart';

/// 🎨 نظام الألوان الموحد للتطبيق - التصميم البنفسجي
///
/// هذا الملف يجمع كل ألوان التطبيق في مكان واحد
/// عند تغيير الألوان، يكفي تعديل هذا الملف فقط وسينعكس على كل التطبيق
/// الألوان مستخرجة من التصميم المرفق (بنفسجي متدرج)
///
/// يدعم 4 ثيمات:
/// 1. Light + Classic: أبيض/بنفسجي - بدون شفافية - مع ظلال
/// 2. Light + Glass: أبيض/بنفسجي - Glassmorphism - مع blur
/// 3. Dark + Classic: أزرق داكن - بدون شفافية - مع ظلال
/// 4. Dark + Glass: أزرق داكن - Glassmorphism - مع blur
///
class AppColors {
  AppColors._();

  // ============= Light Mode Colors =============

  // الألوان الأساسية - البنفسجي (Primary Purple)
  // هذه الألوان تُستخدم في AppBar, الأزرار الرئيسية, والعناصر المهمة

  //////////////////////////////  اخضر  ///////////////////////////////////

  // الألوان الأساسية - الأزرق المخضر (Primary Teal)
  static const Color primaryLight =
      Color(0xFF1877F2); // أزرق مخضر عميق وحديث (Teal 600)
  static const Color primaryLightVariant = Color(0xFF0C5EBF); // أزرق مخضر أغمق
  static const Color primaryContainer =
      Color(0xFFE7F0FD); // أزرق مخضر فاتح جداً للخلفيات

  // اللون الأساسي العام - يُستخدم في Splash Screen والأماكن العامة
  static const Color primary = primaryLight;
  static const Color textWhite = Colors.white;

  // الألوان الثانوية - الأخضر للإشارات الإيجابية
  // كما في التصميم - النقاط الخضراء تشير للعناصر النشطة

  //////////////////////////////  اخضر  ///////////////////////////////////
  ///
  // الألوان الثانوية - الأخضر الليموني الحيوي
  static const Color secondaryLight =
      Color(0xFF84CC16); // أخضر ليموني (Lime 500)
  static const Color secondaryLightVariant =
      Color(0xFF65A30D); // ليموني أغمق قليلاً
  static const Color secondaryContainer = Color(0xFFECFCCB); // ليموني فاتح جداً

  // ألوان الخلفية - رمادي فاتح نظيف
  // تم تغيير من F8FAFC إلى F1F5F9 لتحسين التباين وإصلاح مشاكل اللون الأبيض
  static const Color backgroundLight =
      Color(0xFFF1F5F9); // Slate 100 - أفضل تباين من Slate 50
  static const Color bgLight = Color(0xFFF1F5F9); // اسم بديل
  static const Color surfaceLight = Color(0xFFFFFFFF); // أبيض للبطاقات
  static const Color cardLight = Color(0xFFFFFFFF);

  // ============= ألوان الوضع الكلاسيكي (Classic Mode) =============

  // لون الكارت في الوضع الكلاسيكي الفاتح - أبيض صريح مع ظل
  static const Color cardLightClassic = Color(0xFFFFFFFF);

  // لون حدود الكارت في الوضع الكلاسيكي الفاتح
  static const Color cardBorderLightClassic = Color(0xFFE2E8F0); // Slate 200

  // ============= ألوان الوضع الزجاجي (Glass Mode) =============

  /// لون الكارت في الوضع الزجاجي الفاتح - أبيض شفاف
  /// يُستخدم مع opacity من DesignTokens.glassOpacityLight
  static const Color cardLightGlass = Color(0xFFFFFFFF);

  // لون حدود الزجاج في الوضع الفاتح - أبيض شفاف
  static const Color glassBorderLight = Color(0xFFFFFFFF);

  // لون الزجاج الشفاف للتراكب
  static const Color glassOverlayLight = Color(0xFFFFFFFF);

  // ألوان النص - تدرجات الرمادي للقراءة المريحة
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(
      0xFF475569); // Slate 600 - تعديل اللون ليكون وسطاً بين الغامق والفاتح للأيقونات الثانوية
  // تلميح: تم تغميق لون الـ ليكون مريحاً للأعين ومقروءاً بوضوح على الخلفيات الفاتحة
  static const Color textHintLight =
      Color(0xFF64748B); // Slate 500 - لون رمادي حديث وواضح

  // أسماء بديلة للتوافق مع الكود القديم
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color secondary = secondaryLight;

  // ألوان الحالة - موحدة للوضعين (ليلي/نهاري)
  static const Color success = Color(0xFF10B981); // أخضر - النجاح
  static const Color warning = Color(0xFFF59E0B); // كهرماني - التحذير
  static const Color error = Color(0xFFEF4444); // أحمر - الخطأ
  static const Color info = Color(0xFF3B82F6); // أزرق - المعلومات

  // ألوان الحدود والفواصل
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color dividerLight = Color(0xFFE2E8F0);

  // ============= Dark Mode Colors =============

  //////////////////////////////  اخضر  ///////////////////////////////////
  // الألوان الأساسية للوضع الليلي - أزرق مخضر ساطع
  static const Color primaryDark = Color(0xFF4294FF); // Teal 400
  static const Color primaryDarkVariant = Color(0xFF1877F2);
  static const Color primaryContainerDark = Color(0xFF0A4A99); // Teal 800

  // الألوان الثانوية للوضع الليلي - أخضر ليموني نيون
  static const Color secondaryDark =
      Color(0xFFA3E635); // Lime 400 (تأثير متوهج)
  static const Color secondaryDarkVariant = Color(0xFF84CC16);
  static const Color secondaryContainerDark = Color(0xFF3F6212); // Lime 900

  // ألوان الخلفية للوضع الليلي - أسود داكن جداً (Darker Canvas)
  static const Color backgroundDark =
      Color(0xFF09090B); // Zinc 950 (أسود حقيقي تقريباً)
  static const Color bgDark = Color(0xFF09090B);
  static const Color surfaceDark =
      Color(0xFF18181B); // Zinc 900 (أفتح قليلاً للبطاقات)
  static const Color cardDark = Color(0xFF18181B);

  // لون الكارت في الوضع الكلاسيكي الداكن
  static const Color cardDarkClassic = Color(0xFF18181B);
  // لون حدود الكارت في الوضع الكلاسيكي الداكن
  static const Color cardBorderDarkClassic = Color(0xFF27272A);

  // ============= ألوان الوضع الزجاجي الداكن (Dark Glass Mode) =============
  // لون الكارت في الوضع الزجاجي الداكن - رمادي داكن شفاف
  // يُستخدم مع opacity من DesignTokens.glassOpacityDark
  static const Color cardDarkGlass = Color(0xFF1E293B); // Slate 800

  // لون حدود الزجاج في الوضع الداكن - أبيض شفاف جداً
  static const Color glassBorderDark = Color(0xFFFFFFFF);

  // لون الزجاج الشفاف للتراكب في الوضع الداكن
  static const Color glassOverlayDark = Color(0xFF1E293B);

  // ألوان النص للوضع الليلي
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  // تلميح: تم تفتيح الألوان الثانوية للوضع الليلي لضمان التباين العالي وعدم الجهد في القراءة
  static const Color textSecondaryDark =
      Color(0xFFE2E8F0); // Slate 200 - لون فضي أنيق للنصوص الثانوية
  static const Color textHintDark =
      Color(0xFFCBD5E1); // Slate 300 - لون رمادي فاتح مريح للتلميحات والأيقونات

  // ألوان الحدود للوضع الليلي
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color dividerDark = Color(0xFF334155);

  // ============= Special Colors =============
  // ألوان التدرج للوضع النهاري - من البنفسجي الفاتح إلى الوردي
  // يطابق التصميم المرجعي بألوان ناعمة وأنيقة تعطي إحساساً عصرياً
  // الترتيب: بنفسجي فاتح جداً (أعلى) ← بنفسجي متوسط (وسط) ← وردي فاتح (أسفل)

  //////////////////////////////  اخضر  ///////////////////////////////////
  static const List<Color> gradientLight = [
    Color(0xFFE7F0FD), // Teal 50 - أزرق مخضر فاتح جداً (أعلى)
    Color(0xFFBBD4F9), // Teal 200 - أزرق مخضر متوسط (وسط)
    Color(0xFF8CB8F5), // Emerald 200 - أخضر نعناعي فاتح (أسفل) - بدون صفراء
  ];

  // تدرج الوضع الليلي - تدرج أخضر داكن مرئي
  static const List<Color> gradientDark = [
    Color(0xFF052B5C), // Emerald 900 - أخضر داكن مرئي (أعلى)
    Color(0xFF031A38), // Teal 950 - أزرق مخضر داكن (أسفل)
  ];

  // ألوان الظل
  static Color shadowLight =
      const Color(0xFF64748B).withValues(alpha: 0.08); // Slate based shadow
  static Color shadowDark = Colors.black.withValues(alpha: 0.4);
  static Color get overlay => Colors.black.withValues(alpha: 0.5);

  // ألوان الـ Shimmer Loading Effect
  static const Color shimmerBaseLight = Color(0xFFE2E8F0); // Slate 200
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9); // Slate 100
  static const Color shimmerBaseDark = Color(0xFF1E293B); // Slate 800
  static const Color shimmerHighlightDark = Color(0xFF334155); // Slate 700

  // ألوان للتقارير المالية
  static const Color income = Color(0xFF10B981); // Emerald
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color profit = Color(0xFF8B5CF6); // Violet

  // ألوان الرسوم البيانية - باليت متناسقة
  static const List<Color> chartColors = [
    Color(0xFF8B5CF6), // Violet
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
  ];

  // لون التمييز الخاص - الدوائر الخضراء في التصميم

  //////////////////////////////  اخضر  ///////////////////////////////////
  // لون التمييز الخاص - استبدال الدوائر الخضراء
  static const Color accentPurple = Color(
      0xFF1877F2); // تم تغيير القيمة للأزرق المخضر مع إبقاء الاسم القديم لتجنب أخطاء الكود
  static const Color accentPurpleLight = Color(0xFFBBD4F9);

  // ============= Bottom Navigation Colors =============

  // ألوان شريط التنقل السفلي
  static const Color bottomNavBackground =
      Color(0xFFF3F4F6); // رمادي فاتح متناسق مع الخلفية
  static const Color bottomNavBackgroundDark =
      Color(0xFF1E293B); // Surface Dark

  static const Color bottomNavSelected = primaryLight;
  static const Color bottomNavSelectedDark = primaryDark;
  static const Color bottomNavUnselected = Color(0xFF9CA3AF); // رمادي متوسط
  static const Color bottomNavUnselectedDark = Color(0xFF64748B); // Slate 500

  // ============= Helper Methods =============

  // الحصول على اللون الأساسي حسب الثيم
  static Color getPrimary(bool isDark) => isDark ? primaryDark : primaryLight;

  // الحصول على لون الخلفية حسب الثيم
  static Color getBackground(bool isDark) =>
      isDark ? backgroundDark : backgroundLight;

  // الحصول على لون النص الأساسي حسب الثيم
  static Color getTextPrimary(bool isDark) =>
      isDark ? textPrimaryDark : textPrimaryLight;

  // الحصول على لون الـ Surface حسب الثيم
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surfaceLight;

  // الحصول على Gradient حسب الثيم
  static List<Color> getGradient(bool isDark) =>
      isDark ? gradientDark : gradientLight;

  // الحصول على ألوان Bottom Navigation حسب الثيم
  static Color getBottomNavBackground(bool isDark) =>
      isDark ? bottomNavBackgroundDark : bottomNavBackground;

  static Color getBottomNavSelected(bool isDark) =>
      isDark ? bottomNavSelectedDark : bottomNavSelected;

  static Color getBottomNavUnselected(bool isDark) =>
      isDark ? bottomNavUnselectedDark : bottomNavUnselected;

  // الحصول على لون النص الثانوي حسب الثيم
  static Color getTextSecondary(bool isDark) =>
      isDark ? textSecondaryDark : textSecondaryLight;

  // الحصول على لون النص التلميح (HintText) حسب الثيم
  static Color getTextHint(bool isDark) =>
      isDark ? textHintDark : textHintLight;

  // الحصول على لون الحدود حسب الثيم
  static Color getBorder(bool isDark) => isDark ? borderDark : borderLight;

  // الحصول على لون الفاصل (Divider) حسب الثيم
  static Color getDivider(bool isDark) => isDark ? dividerDark : dividerLight;

  // الحصول على ألوان الثانوي حسب الثيم
  static Color getSecondary(bool isDark) =>
      isDark ? secondaryDark : secondaryLight;

  // الحصول على لون الظل حسب الثيم
  static Color getShadow(bool isDark) => isDark ? shadowDark : shadowLight;

  // الحصول على لون البطاقة حسب الثيم
  static Color getCard(bool isDark) => isDark ? cardDark : cardLight;

  // دالة شاملة للحصول على أي لون حسب الثيم والنوع
  // استخدم: AppColors.getColorByType('text_primary', isDark)
  static Color getColorByType(String colorType, bool isDark) {
    switch (colorType.toLowerCase()) {
      case 'primary':
        return getPrimary(isDark);
      case 'secondary':
        return getSecondary(isDark);
      case 'background':
        return getBackground(isDark);
      case 'surface':
        return getSurface(isDark);
      case 'card':
        return getCard(isDark);
      case 'text_primary':
        return getTextPrimary(isDark);
      case 'text_secondary':
        return getTextSecondary(isDark);
      case 'text_hint':
        return getTextHint(isDark);
      case 'border':
        return getBorder(isDark);
      case 'divider':
        return getDivider(isDark);
      case 'shadow':
        return getShadow(isDark);
      case 'error':
        return error;
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'info':
        return info;
      default:
        return getTextPrimary(isDark);
    }
  }
}

// امتداد لتسهيل الوصول للألوان من BuildContext
// استخدم: context.primaryColor بدلاً من Theme.of(context).colorScheme.primary
extension AppColorsExtension on BuildContext {
  // هل الثيم الحالي داكن؟
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// الحصول على اللون الأساسي
  Color get primaryColor => AppColors.getPrimary(isDarkMode);

  /// الحصول على لون الخلفية
  Color get backgroundColor => AppColors.getBackground(isDarkMode);

  /// الحصول على لون النص الأساسي
  Color get textColor => AppColors.getTextPrimary(isDarkMode);

  /// الحصول على لون الـ Surface
  Color get surfaceColor => AppColors.getSurface(isDarkMode);

  // الحصول على التدرج اللوني
  List<Color> get gradientColors => AppColors.getGradient(isDarkMode);

  // الحصول على لون النص الثانوي
  Color get secondaryTextColor => AppColors.getTextSecondary(isDarkMode);

  // الحصول على لون نص التلميح (HintText)
  Color get hintTextColor => AppColors.getTextHint(isDarkMode);

  // الحصول على لون الحدود
  Color get borderColor => AppColors.getBorder(isDarkMode);

  // الحصول على لون الفاصل
  Color get dividerColor => AppColors.getDivider(isDarkMode);

  // الحصول على اللون الثانوي
  Color get secondaryColor => AppColors.getSecondary(isDarkMode);

  // الحصول على لون البطاقة
  Color get cardColor => AppColors.getCard(isDarkMode);

  // الحصول على لون الظل
  Color get shadowColor => AppColors.getShadow(isDarkMode);

  // الحصول على لون النص بناءً على النوع
  // أنواع: primary, secondary,
  Color getTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'secondary':
        return secondaryTextColor;
      case 'hint':
        return hintTextColor;
      case 'primary':
      default:
        return textColor;
    }
  }

  // الحصول على ألوان Bottom Navigation
  Color get bottomNavBackgroundColor =>
      AppColors.getBottomNavBackground(isDarkMode);

  Color get bottomNavSelectedColor =>
      AppColors.getBottomNavSelected(isDarkMode);

  Color get bottomNavUnselectedColor =>
      AppColors.getBottomNavUnselected(isDarkMode);

  // الحصول على إحدى ألوان الحالة (Success, Error, Warning, Info)
  // استخدم: context.statusColor('success')
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'error':
        return AppColors.error;
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }

  // دالة شاملة للحصول على أي لون
  Color getAppColor(String colorName) =>
      AppColors.getColorByType(colorName, isDarkMode);
}
