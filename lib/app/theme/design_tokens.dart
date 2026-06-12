/// 🎨 ثوابت التصميم الموحدة (Design Tokens)
///
///  هذا الملف يجمع كل ثوابت التصميم في مكان واحد
///  استخدم هذه الثوابت بدلاً من كتابة الأرقام مباشرة في الكود
///  عند تغيير أي قيمة هنا، ستتغير في كل التطبيق تلقائياً
///
/// الاستخدام:
/// ```dart
/// import 'package:craftsman_iraq/app/theme/design_tokens.dart';
///
/// borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)
/// padding: EdgeInsets.all(DesignTokens.spacing16)
/// ```
///
/// تاريخ الإنشاء: 2026-02-05
/// الغرض: توحيد قيم التصميم لدعم 4 ثيمات (Light/Dark × Classic/Glass)
library;

///  وضع التصميم - يحدد شكل المكونات (كروت، أزرار، إلخ)
/// Classic: تصميم تقليدي مع ظلال و elevation
/// Glass: تصميم زجاجي مع شفافية و blur
enum DesignMode {
  ///  الوضع الكلاسيكي - ظلال، elevation، بدون شفافية
  classic,

  ///  الوضع الزجاجي - شفافية، blur، حدود خفيفة
  glass,
}

/// ثوابت التصميم الموحدة
///
///  استخدم هذه الثوابت في كل مكان بدلاً من الأرقام المباشرة
///  هذا يضمن اتساق التصميم ويسهل التعديل لاحقاً
class DesignTokens {
  DesignTokens._();

  // ============= نصف قطر الزوايا (Border Radius) =============

  ///  زوايا صغيرة - للعناصر الصغيرة مثل Chips و Tags
  static const double radiusXSmall = 4.0;

  ///  زوايا صغيرة - للأزرار الصغيرة وحقول الإدخال
  static const double radiusSmall = 8.0;

  ///  زوايا متوسطة - للكروت في الوضع Classic
  static const double radiusMedium = 12.0;

  ///  زوايا كبيرة - للكروت في الوضع Glass
  static const double radiusLarge = 16.0;

  ///  زوايا كبيرة جداً - للـ Dialogs و Bottom Sheets
  static const double radiusXLarge = 20.0;

  ///  زوايا دائرية كاملة - للأزرار الدائرية و Avatars
  static const double radiusCircle = 100.0;

  // ============= الظلال (Elevation) - للوضع Classic فقط =============

  ///  بدون ظل - للوضع Glass
  static const double elevationNone = 0.0;

  ///  ظل خفيف - للكروت العادية
  static const double elevationSmall = 2.0;

  ///  ظل متوسط - للكروت المرتفعة
  static const double elevationMedium = 4.0;

  ///  ظل قوي - للـ Dialogs و FAB
  static const double elevationLarge = 8.0;

  // ============= المسافات (Spacing) =============

  ///  مسافة صغيرة جداً - بين العناصر المتقاربة
  static const double spacing4 = 4.0;

  ///  مسافة صغيرة - padding داخلي للعناصر الصغيرة
  static const double spacing8 = 8.0;

  ///  مسافة متوسطة صغيرة
  static const double spacing12 = 12.0;

  ///  مسافة متوسطة - padding الأساسي للكروت
  static const double spacing16 = 16.0;

  ///  مسافة كبيرة - بين الأقسام
  static const double spacing24 = 24.0;

  ///  مسافة كبيرة جداً - margin للشاشات
  static const double spacing32 = 32.0;

  // ============= إعدادات الوضع الزجاجي (Glass Mode) =============

  ///  مستوى الضبابية في الوضع الفاتح - قيمة أقل لوضوح أفضل
  static const double glassBlurLight = 10.0;

  ///  مستوى الضبابية في الوضع الداكن - قيمة أعلى لتأثير أقوى
  static const double glassBlurDark = 12.0;

  ///  شفافية الخلفية في الوضع الفاتح - أعلى لأن الخلفية فاتحة
  static const double glassOpacityLight = 0.7;

  ///  شفافية الخلفية في الوضع الداكن - أقل لأن الخلفية داكنة
  static const double glassOpacityDark = 0.5;

  ///  سمك حدود الزجاج
  static const double glassBorderWidth = 1.0;

  ///  شفافية حدود الزجاج في الوضع الفاتح
  static const double glassBorderOpacityLight = 0.2;

  ///  شفافية حدود الزجاج في الوضع الداكن
  static const double glassBorderOpacityDark = 0.1;

  // ============= إعدادات الوضع الكلاسيكي (Classic Mode) =============

  ///  سمك حدود الكروت في الوضع الكلاسيكي
  static const double classicBorderWidth = 0.5;

  ///  شفافية الظل في الوضع الفاتح
  static const double classicShadowOpacityLight = 0.08;

  ///  شفافية الظل في الوضع الداكن
  static const double classicShadowOpacityDark = 0.4;

  // ============= أحجام الأيقونات =============

  ///  أيقونة صغيرة - في القوائم
  static const double iconSmall = 16.0;

  ///  أيقونة متوسطة - الحجم الافتراضي
  static const double iconMedium = 24.0;

  ///  أيقونة كبيرة - في الأزرار الكبيرة
  static const double iconLarge = 32.0;

  ///  أيقونة كبيرة جداً - في صفحات الخطأ والنجاح
  static const double iconXLarge = 48.0;

  // ============= دوال مساعدة =============

  ///  الحصول على نصف قطر الزوايا حسب وضع التصميم
  /// الوضع الزجاجي يستخدم زوايا أكبر
  static double getCardRadius(DesignMode mode) {
    return mode == DesignMode.glass ? radiusLarge : radiusMedium;
  }

  ///  الحصول على elevation حسب وضع التصميم
  /// الوضع الزجاجي لا يستخدم elevation
  static double getCardElevation(DesignMode mode) {
    return mode == DesignMode.glass ? elevationNone : elevationSmall;
  }

  ///  الحصول على مستوى الضبابية حسب السطوع
  static double getGlassBlur(bool isDark) {
    return isDark ? glassBlurDark : glassBlurLight;
  }

  ///  الحصول على شفافية الزجاج حسب السطوع
  static double getGlassOpacity(bool isDark) {
    return isDark ? glassOpacityDark : glassOpacityLight;
  }

  ///  الحصول على نصف قطر الزوايا حسب وضع التصميم (bool)
  /// يستخدم مع GlassContainer
  static double getRadius(bool isGlass) {
    return isGlass ? radiusLarge : radiusMedium;
  }
}
