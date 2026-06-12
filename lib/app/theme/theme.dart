/// 🎨 نقطة دخول موحدة لجميع الملفات الخاصة بالثيم
///
///  استخدم هذا الملف لاستيراد كل ما تحتاجه من الثيم
///  بدلاً من:
///   import 'package:craftsman_iraq/app/theme/app_colors.dart';
///   import 'package:craftsman_iraq/app/theme/app_text_styles.dart';
///   import 'package:craftsman_iraq/app/theme/app_color_system.dart';
///   import 'package:craftsman_iraq/app/theme/app_theme.dart';
///   import 'package:craftsman_iraq/app/theme/design_tokens.dart';
///
///  استخدم:
///   import 'package:craftsman_iraq/app/theme/theme.dart';
///
///  يدعم 4 ثيمات:
/// - Light + Classic | Light + Glass
/// - Dark + Classic | Dark + Glass
///
/// كل شيء الذي تحتاجه يكون متاحاً الآن!
///
/// تاريخ آخر تحديث: 2026-02-05
library;

//  ثوابت التصميم الموحدة (الجديد)
export 'design_tokens.dart';

//  الألوان الأساسية والموحدة
export 'app_colors.dart';

//  أنماط النصوص
export 'app_text_styles.dart';

//  نظام الألوان المتقدم
export 'app_color_system.dart';

//  إعدادات الثيم الشاملة (4 ثيمات)
export 'app_theme.dart';

//  ملفات ثيمات المكونات الفرعية (مستخرجة من app_theme.dart)
export 'input_theme.dart';
export 'button_theme.dart';
export 'card_theme.dart';
export 'navigation_theme.dart';
