import 'dart:math';

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام الألوان المتقدم والشامل للتطبيق
///
/// هذا الملف يوفر طريقة سهلة وموحدة للعمل مع الألوان والأنماط
/// بدلاً من البحث عن الألوان، استخدم الدوال هنا مباشرة
/// كل دالة موثقة بوضوح مع أمثلة على الاستخدام
class AppColorSystem {
  AppColorSystem._();

  // ============= Icon Colors =============

  /// الحصول على لون الأيقونة الأساسية
  /// الاستخدام:
  /// Icon(Icons.home, color: AppColorSystem.getIconColor(context))
  static Color getIconColor(bool isDark) =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  /// الحصول على لون الأيقونة الثانوية (أقل بروزاً)
  static Color getSecondaryIconColor(bool isDark) =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  /// الحصول على لون الأيقونة المضغوطة (عند الضغط)
  static Color getPressedIconColor(bool isDark) =>
      isDark ? AppColors.primaryDark : AppColors.primaryLight;

  /// الحصول على لون الأيقونة المعطلة (غير نشطة)
  static Color getDisabledIconColor(bool isDark) =>
      isDark ? AppColors.textHintDark : AppColors.textHintLight;

  // ============= Button Colors =============

  /// ألوان الزر الأساسي (Primary Button)
  /// الاستخدام:
  /// ElevatedButton(
  ///   style: ElevatedButton.styleFrom(
  ///     backgroundColor: AppColorSystem.getPrimaryButtonColor(isDark),
  ///     foregroundColor: AppColorSystem.getPrimaryButtonTextColor(isDark),
  ///   ),
  ///   onPressed: () {},
  ///   child: Text('زر'),
  /// )
  static Color getPrimaryButtonColor(bool isDark) =>
      isDark ? AppColors.primaryDark : AppColors.primaryLight;

  static Color getPrimaryButtonTextColor(bool isDark) => Colors.white;

  /// ألوان الزر الثانوي
  static Color getSecondaryButtonColor(bool isDark) =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  static Color getSecondaryButtonTextColor(bool isDark) =>
      AppColorSystem.getIconColor(isDark);

  /// ألوان الزر الخطر (Delete, etc.)
  static Color getDangerButtonColor(bool isDark) => AppColors.error;

  static Color getDangerButtonTextColor(bool isDark) => Colors.white;

  /// ألوان الزر الناجح
  static Color getSuccessButtonColor(bool isDark) => AppColors.success;

  static Color getSuccessButtonTextColor(bool isDark) => Colors.white;

  /// ألوان الزر المعطل
  static Color getDisabledButtonColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  static Color getDisabledButtonTextColor(bool isDark) =>
      AppColorSystem.getDisabledIconColor(isDark);

  // ============= Input Field Colors =============

  /// ألوان حقول الإدخال (TextField)
  /// الاستخدام:
  /// TextField(
  ///   decoration: InputDecoration(
  ///     fillColor: AppColorSystem.getInputBackgroundColor(isDark),
  ///     filled: true,
  ///     border: OutlineInputBorder(
  ///       borderSide: BorderSide(
  ///         color: AppColorSystem.getInputBorderColor(isDark),
  ///       ),
  ///     ),
  ///   ),
  /// )
  static Color getInputBackgroundColor(bool isDark) =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  static Color getInputBorderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  static Color getInputBorderFocusedColor(bool isDark) =>
      AppColorSystem.getPrimaryButtonColor(isDark);

  static Color getInputTextColor(bool isDark) =>
      AppColorSystem.getIconColor(isDark);

  static Color getInputCursorColor(bool isDark) =>
      AppColorSystem.getPrimaryButtonColor(isDark);

  static Color getInputHintColor(bool isDark) =>
      AppColorSystem.getDisabledIconColor(isDark);

  // ============= Card and Surface Colors =============

  /// ألوان البطاقات والأسطح
  /// الاستخدام:
  /// Card(
  ///   color: AppColorSystem.getCardColor(isDark),
  ///   child: Container(...)
  /// )
  static Color getCardColor(bool isDark) =>
      isDark ? AppColors.cardDark : AppColors.cardLight;

  static Color getCardBorderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  static Color getSurfaceColor(bool isDark) =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  // ============= Overlay and Shadow Colors =============

  /// ألوان الظلال والرقائق الشفافة
  /// الاستخدام:
  /// Container(
  ///   decoration: BoxDecoration(
  ///     boxShadow: [
  ///       BoxShadow(
  ///         color: AppColorSystem.getShadowColor(isDark),
  ///         blurRadius: 8,
  ///         offset: Offset(0, 2),
  ///       ),
  ///     ],
  ///   ),
  /// )
  static Color getShadowColor(bool isDark) =>
      isDark ? AppColors.shadowDark : AppColors.shadowLight;

  static Color getOverlayColor(bool isDark) => AppColors.overlay;

  // ============= Status Colors =============

  /// ألوان الحالات (Success, Error, Warning, Info)
  /// الاستخدام:
  /// Container(
  ///   color: AppColorSystem.getStatusColor('error', isDark),
  /// )
  static Color getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'error':
      case 'danger':
      case 'failed':
        return AppColors.error;
      case 'success':
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'warning':
      case 'pending':
      case 'attention':
        return AppColors.warning;
      case 'info':
      case 'notification':
      case 'message':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }

  /// الحصول على لون نص الحالة
  static Color getStatusTextColor(String status, bool isDark) {
    // جميع نصوص الحالات بيضاء للتمييز الجيد
    return Colors.white;
  }

  /// الحصول على لون خلفية الحالة الفاتح
  static Color getStatusBackgroundColor(String status, bool isDark) {
    final statusColor = getStatusColor(status, isDark);
    return statusColor.withValues(alpha: 0.1);
  }

  // ============= Bottom Navigation Colors =============

  /// ألوان شريط التنقل السفلي
  /// الاستخدام:
  /// BottomNavigationBar(
  ///   backgroundColor: AppColorSystem.getBottomNavBackgroundColor(isDark),
  ///   selectedItemColor: AppColorSystem.getBottomNavSelectedColor(isDark),
  ///   unselectedItemColor: AppColorSystem.getBottomNavUnselectedColor(isDark),
  /// )
  static Color getBottomNavBackgroundColor(bool isDark) =>
      AppColors.getBottomNavBackground(isDark);

  static Color getBottomNavSelectedColor(bool isDark) =>
      AppColors.getBottomNavSelected(isDark);

  static Color getBottomNavUnselectedColor(bool isDark) =>
      AppColors.getBottomNavUnselected(isDark);

  // ============= Gradient Colors =============

  /// التدرجات اللونية
  /// الاستخدام:
  /// Container(
  ///   decoration: BoxDecoration(
  ///     gradient: LinearGradient(
  ///       colors: AppColorSystem.getGradient(isDark),
  ///       begin: AlignmentDirectional.topStart,
  ///       end: AlignmentDirectional.bottomEnd,
  ///     ),
  ///   ),
  /// )
  static List<Color> getGradient(bool isDark) => AppColors.getGradient(isDark);

  // ============= Divider and Border Colors =============

  /// ألوان الفواصل والحدود
  /// الاستخدام:
  /// Divider(
  ///   color: AppColorSystem.getDividerColor(isDark),
  /// )
  static Color getDividerColor(bool isDark) => AppColors.getDivider(isDark);

  static Color getBorderColor(bool isDark) => AppColors.getBorder(isDark);

  /// الحصول على لون الحد مع شفافية
  static Color getBorderColorWithAlpha(bool isDark, double alpha) =>
      getBorderColor(isDark).withValues(alpha: alpha);

  // ============= Skeleton Loading Colors =============

  /// ألوان تأثير التحميل (Skeleton Loading)
  /// الاستخدام:
  /// Container(
  ///   color: AppColorSystem.getSkeletonBaseColor(isDark),
  ///   child: Shimmer.fromColors(
  ///     baseColor: AppColorSystem.getSkeletonBaseColor(isDark),
  ///     highlightColor: AppColorSystem.getSkeletonHighlightColor(isDark),
  ///     child: Container(),
  ///   ),
  /// )
  static Color getSkeletonBaseColor(bool isDark) =>
      isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight;

  static Color getSkeletonHighlightColor(bool isDark) =>
      isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight;

  // ============= Chart Colors =============

  /// ألوان الرسوم البيانية
  /// الاستخدام:
  /// `List<Color>` colors = AppColorSystem.getChartColors();
  static List<Color> getChartColors() => AppColors.chartColors;

  /// الحصول على لون واحد من ألوان الرسم البياني
  static Color getChartColor(int index) {
    final colors = AppColors.chartColors;
    return colors[index % colors.length];
  }

  // ============= Financial Colors =============

  /// الألوان المالية (Income vs Expense)
  /// الاستخدام:
  /// Container(
  ///   color: AppColorSystem.getFinancialColor('income'),
  /// )
  static Color getFinancialColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
      case 'revenue':
        return AppColors.income;
      case 'expense':
      case 'cost':
        return AppColors.expense;
      case 'profit':
      case 'gain':
        return AppColors.profit;
      default:
        return AppColors.primary;
    }
  }

  // ============= Accessibility Colors =============

  /// التحقق من تباين اللون (للامتثال WCAG)
  /// الاستخدام:
  /// bool isAccessible = AppColorSystem.hasGoodContrast(textColor, backgroundColor);
  static bool hasGoodContrast(Color foreground, Color background) {
    // حساب اللمعان النسبي
    final fgLuminance = _getLuminance(foreground);
    final bgLuminance = _getLuminance(background);

    // النسبة المتناقضة (يجب أن تكون >= 4.5 للنصوص العادية)
    final contrast = (max(fgLuminance, bgLuminance) + 0.05) /
        (min(fgLuminance, bgLuminance) + 0.05);

    return contrast >= 4.5;
  }

  /// دالة مساعدة لحساب اللمعان (Luminance)
  /// تحديث من deprecated APIs (color.red/green/blue -> color.r/g/b)
  static double _getLuminance(Color color) {
    // استخدام الـ APIs الجديدة التي تعيد قيم من 0.0 إلى 1.0
    final r = color.r;
    final g = color.g;
    final b = color.b;

    return (0.299 * r + 0.587 * g + 0.114 * b);
  }

  // ============= Glass-Aware Empty State Colors =============

  /// لون أيقونة/محتوى حالة الفراغ (Empty State)
  /// في الوضع الزجاجي النهاري نستخدم لون primary لأن الرمادي يختفي على الخلفية الخضراء الفاتحة
  static Color getEmptyStateColor(bool isDark, bool isGlass) {
    if (isGlass && !isDark) {
      return AppColors.primaryLightVariant.withValues(alpha: 0.55);
    }
    if (isDark) return Colors.white.withValues(alpha: 0.3);
    return Colors.grey.withValues(alpha: 0.5);
  }

  /// لون النص الثانوي / التلميح في حالة الفراغ
  static Color getEmptyStateTextColor(bool isDark, bool isGlass) {
    if (isGlass && !isDark) return AppColors.primaryLightVariant;
    if (isDark) return Colors.white60;
    return const Color(0xFF757575); // Colors.grey[600]
  }

  /// لون الحالة المعطلة (Disabled) للأيقونات والأزرار
  static Color getDisabledColor(bool isDark, bool isGlass) {
    if (isGlass && !isDark) {
      return AppColors.primaryLightVariant.withValues(alpha: 0.4);
    }
    if (isDark) return Colors.white38;
    return Colors.grey;
  }

  // ============= Utility Methods =============

  /// دالة شاملة للحصول على أي لون حسب اسمه والثيم
  /// الأسماء المتاحة: icon, secondary_icon, disabled_icon,
  /// primary_button, secondary_button, danger_button, success_button, disabled_button,
  /// input_background, input_border, input_text,
  /// card, surface, shadow, divider, border
  static Color getColorByName(String colorName, bool isDark) {
    final name = colorName.toLowerCase();

    // Icon Colors
    if (name == 'icon') return getIconColor(isDark);
    if (name == 'secondary_icon') return getSecondaryIconColor(isDark);
    if (name == 'disabled_icon') return getDisabledIconColor(isDark);

    // Button Colors
    if (name == 'primary_button') return getPrimaryButtonColor(isDark);
    if (name == 'secondary_button') return getSecondaryButtonColor(isDark);
    if (name == 'danger_button') return getDangerButtonColor(isDark);
    if (name == 'success_button') return getSuccessButtonColor(isDark);
    if (name == 'disabled_button') return getDisabledButtonColor(isDark);

    // Input Colors
    if (name == 'input_background') return getInputBackgroundColor(isDark);
    if (name == 'input_border') return getInputBorderColor(isDark);
    if (name == 'input_text') return getInputTextColor(isDark);

    // Surface Colors
    if (name == 'card') return getCardColor(isDark);
    if (name == 'surface') return getSurfaceColor(isDark);

    // Other
    if (name == 'shadow') return getShadowColor(isDark);
    if (name == 'divider') return getDividerColor(isDark);
    if (name == 'border') return getBorderColor(isDark);

    // Default
    return getIconColor(isDark);
  }

  /// دالة للحصول على ظل (Shadow) مناسب
  /// الاستخدام:
  /// Container(
  ///   decoration: BoxDecoration(
  ///     boxShadow: [AppColorSystem.getBoxShadow(isDark)],
  ///   ),
  /// )
  static BoxShadow getBoxShadow(bool isDark, {double elevation = 2}) {
    return BoxShadow(
      color: getShadowColor(isDark),
      blurRadius: elevation * 4,
      offset: Offset(0, elevation),
    );
  }

  /// دالة للحصول على عدة ظلال
  static List<BoxShadow> getBoxShadows(bool isDark) {
    return [
      getBoxShadow(isDark, elevation: 1),
      getBoxShadow(isDark, elevation: 2),
    ];
  }
}

/// امتداد لتسهيل الوصول إلى نظام الألوان من BuildContext
/// الاستخدام:
/// Container(
///   color: context.appIconColor,
///   child: Text('Hello', style: TextStyle(
///     color: context.appPrimaryTextColor,
///   )),
/// )
extension AppColorSystemExtension on BuildContext {
  /// هل الثيم الحالي داكن؟
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // ألوان الأيقونات
  Color get appIconColor => AppColorSystem.getIconColor(_isDark);

  Color get appSecondaryIconColor =>
      AppColorSystem.getSecondaryIconColor(_isDark);

  Color get appDisabledIconColor =>
      AppColorSystem.getDisabledIconColor(_isDark);

  // ألوان الأزرار
  Color get appPrimaryButtonColor =>
      AppColorSystem.getPrimaryButtonColor(_isDark);

  Color get appSecondaryButtonColor =>
      AppColorSystem.getSecondaryButtonColor(_isDark);

  Color get appDangerButtonColor =>
      AppColorSystem.getDangerButtonColor(_isDark);

  Color get appSuccessButtonColor =>
      AppColorSystem.getSuccessButtonColor(_isDark);

  // ألوان الإدخال
  Color get appInputBackgroundColor =>
      AppColorSystem.getInputBackgroundColor(_isDark);

  Color get appInputBorderColor => AppColorSystem.getInputBorderColor(_isDark);

  Color get appInputTextColor => AppColorSystem.getInputTextColor(_isDark);

  // ألوان الأسطح والبطاقات
  Color get appCardColor => AppColorSystem.getCardColor(_isDark);

  Color get appSurfaceColor => AppColorSystem.getSurfaceColor(_isDark);

  // ألوان أخرى
  Color get appShadowColor => AppColorSystem.getShadowColor(_isDark);

  Color get appDividerColor => AppColorSystem.getDividerColor(_isDark);

  Color get appBorderColor => AppColorSystem.getBorderColor(_isDark);

  // ألوان الحالات
  Color appStatusColor(String status) =>
      AppColorSystem.getStatusColor(status, _isDark);

  // الحصول على لون حسب الاسم
  Color getAppColor(String colorName) =>
      AppColorSystem.getColorByName(colorName, _isDark);

  // الحصول على ظل
  BoxShadow get appBoxShadow => AppColorSystem.getBoxShadow(_isDark);

  // الحصول على عدة ظلال
  List<BoxShadow> get appBoxShadows => AppColorSystem.getBoxShadows(_isDark);
}
