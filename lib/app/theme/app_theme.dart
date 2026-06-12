import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'design_tokens.dart';
import 'input_theme.dart';
import 'button_theme.dart';
import 'card_theme.dart';
import 'navigation_theme.dart';

/// إعدادات الثيم للتطبيق - التصميم البنفسجي
///
/// هذا الكلاس يجمع إعدادات المظهر للوضع الليلي والنهاري
/// يستخدم الألوان من AppColors لضمان التناسق
/// لتغيير مظهر أي عنصر في التطبيق، عدّل هنا
///
/// يدعم 4 ثيمات:
/// 1. Light + Classic: تصميم فاتح مع ظلال و elevation
/// 2. Light + Glass: تصميم فاتح زجاجي مع blur وشفافية
/// 3. Dark + Classic: تصميم داكن مع ظلال و elevation
/// 4. Dark + Glass: تصميم داكن زجاجي مع blur وشفافية
///
/// الاستخدام:
/// ```dart
/// // للحصول على ثيم محدد
/// final theme = AppTheme.getTheme(
///   brightness: Brightness.light,
///   designMode: DesignMode.glass,
/// );
///
/// // أو استخدام الثيمات الجاهزة
/// MaterialApp(
///   theme: AppTheme.lightClassicTheme,
///   darkTheme: AppTheme.darkClassicTheme,
/// );
/// ```
///
/// تم تقسيم ثيمات المكونات إلى ملفات منفصلة لسهولة الصيانة:
/// - input_theme.dart — ثيمات حقول الإدخال
/// - button_theme.dart — ثيمات الأزرار
/// - card_theme.dart — ثيمات البطاقات والحوارات
/// - navigation_theme.dart — ثيمات التنقل والأشرطة
///
/// تاريخ آخر تحديث: 2026-02-26
class AppTheme {
  AppTheme._();

  // ============= مصنع الثيمات (Theme Factory) =============

  // الحصول على الثيم المناسب حسب السطوع ووضع التصميم
  // هذه الدالة هي الطريقة المفضلة للحصول على الثيم
  static ThemeData getTheme({
    required Brightness brightness,
    required DesignMode designMode,
  }) {
    final isDark = brightness == Brightness.dark;
    final isGlass = designMode == DesignMode.glass;

    if (isDark) {
      return isGlass ? darkGlassTheme : darkClassicTheme;
    } else {
      return isGlass ? lightGlassTheme : lightClassicTheme;
    }
  }

  // ============= الثيمات الأربعة الجديدة =============

  // 1. الثيم الفاتح الكلاسيكي
  // تصميم نظيف مع ظلال خفيفة و elevation
  // زوايا متوسطة (12px) - بدون شفافية
  static ThemeData get lightClassicTheme => _buildLightTheme(isGlass: false);

  // 2. الثيم الفاتح الزجاجي
  /// تصميم شفاف مع blur - بدون elevation
  /// زوايا كبيرة (16px) - مع حدود شفافة
  static ThemeData get lightGlassTheme => _buildLightTheme(isGlass: true);

  // 3. الثيم الداكن الكلاسيكي
  // تصميم داكن مع ظلال - elevation أعلى
  // زوايا متوسطة (12px) - بدون شفافية
  static ThemeData get darkClassicTheme => _buildDarkTheme(isGlass: false);

  // 4. الثيم الداكن الزجاجي
  // تصميم داكن شفاف مع blur قوي
  // زوايا كبيرة (16px) - مع حدود شفافة
  static ThemeData get darkGlassTheme => _buildDarkTheme(isGlass: true);

  // ============= الثيمات القديمة (للتوافق Backward Compatibility) =============

  // الثيم الفاتح القديم - يُستخدم الكلاسيكي افتراضياً
  // للتوافق مع الكود القديم فقط - استخدم lightClassicTheme بدلاً منه
  static ThemeData get lightTheme => lightClassicTheme;

  // الثيم الداكن القديم - يُستخدم الكلاسيكي افتراضياً
  // للتوافق مع الكود القديم فقط - استخدم darkClassicTheme بدلاً منه
  static ThemeData get darkTheme => darkClassicTheme;

  // ============= بناء الثيم الفاتح =============

  // بناء الثيم الفاتح (مشترك بين Classic و Glass)
  // يستخدم الـ builders من الملفات الفرعية لبناء كل مكون
  static ThemeData _buildLightTheme({required bool isGlass}) {
    // اختيار قيم مختلفة حسب وضع التصميم
    final cardRadius =
        isGlass ? DesignTokens.radiusLarge : DesignTokens.radiusMedium;
    final cardElevation =
        isGlass ? DesignTokens.elevationNone : DesignTokens.elevationSmall;
    final buttonRadius =
        isGlass ? DesignTokens.radiusLarge : DesignTokens.radiusMedium;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // نظام الألوان - يحدد كل ألوان Material Design
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryLightVariant,
        secondary: AppColors.secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondaryLightVariant,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        // تلميح: تم ربط الـ onSurfaceVariant بالنص الثانوي ليستخدم تلقائياً للنصوص الوصفية
        onSurfaceVariant: AppColors.textSecondaryLight,
        // تلميح هام: تم استبدال لون outline من لون الحدود الباهت إلى لون الواضح
        // هذا سيحل مشكلة زر الإبلاغ (Report) وكافة الأيقونات والنصوص الثانوية المعتمدة عليه
        outline: AppColors.textHintLight,
        outlineVariant: AppColors.borderLight, // مخصص للحدود والفواصل الخفيفة
        shadow: Colors.black12,
      ),

      // لون خلفية الشاشة
      scaffoldBackgroundColor: AppColors.backgroundLight,
      canvasColor: AppColors.backgroundLight,

      // المكونات المستخرجة من الملفات الفرعية
      appBarTheme: NavigationThemeBuilder.buildLightAppBar(isGlass: isGlass),
      cardTheme: CardThemeBuilder.buildLight(
        isGlass: isGlass,
        cardRadius: cardRadius,
        cardElevation: cardElevation,
      ),
      elevatedButtonTheme: ButtonThemeBuilder.buildLightElevated(
        isGlass: isGlass,
        buttonRadius: buttonRadius,
      ),
      outlinedButtonTheme: ButtonThemeBuilder.buildLightOutlined(
        isGlass: isGlass,
        buttonRadius: buttonRadius,
      ),
      textButtonTheme: ButtonThemeBuilder.buildLightText(),
      inputDecorationTheme: InputThemeBuilder.buildLight(
        isGlass: isGlass,
        cardRadius: cardRadius,
      ),
      dialogTheme: CardThemeBuilder.buildLightDialog(isGlass: isGlass),
      drawerTheme: CardThemeBuilder.buildLightDrawer(isGlass: isGlass),
      bottomNavigationBarTheme:
          NavigationThemeBuilder.buildLightBottomNav(isGlass: isGlass),
      tabBarTheme: NavigationThemeBuilder.buildLightTabBar(),
      bottomSheetTheme:
          CardThemeBuilder.buildLightBottomSheet(isGlass: isGlass),

      // ثيم الفواصل
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 16,
      ),

      // ثيم عناصر القائمة
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
        iconColor: AppColors.textSecondaryLight,
        textColor: AppColors.textPrimaryLight,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      // ثيم الأيقونات
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: 24,
      ),

      // ثيم FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: isGlass ? 0 : 4,
        // تلميح: تمت إزالة التقييد الدائري الإجباري (CircleBorder) للسماح للأزرار الممتدة (Extended) بأخذ شكلها المستطيل العصري والطبيعي
      ),

      // ثيم Chip
      chipTheme: ChipThemeData(
        backgroundColor: isGlass
            ? AppColors.primaryContainer.withValues(alpha: 0.7)
            : AppColors.primaryContainer,
        labelStyle: const TextStyle(
          color: AppColors.primaryLightVariant,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ثيم النصوص - فاتح
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
          fontFamily: 'Cairo',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryLight,
          fontFamily: 'Cairo',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          fontFamily: 'Cairo',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
          fontFamily: 'Cairo',
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textHintLight,
          fontFamily: 'Cairo',
        ),
      ),

      // ثيم Checkbox - فاتح
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.borderLight, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ثيم Radio - فاتح
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.borderLight;
        }),
      ),

      // ثيم Switch - فاتح
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.textHintLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withValues(alpha: 0.5);
          }
          return AppColors.borderLight;
        }),
      ),

      // ثيم ProgressIndicator - فاتح
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
      ),

      // ثيم SnackBar - فاتح
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ثيم القائمة المنبثقة
      popupMenuTheme: PopupMenuThemeData(
        color: isGlass
            ? AppColors.surfaceLight.withValues(alpha: 0.95)
            : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: isGlass ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 14,
            fontFamily: 'Cairo',
          ),
        ),
      ),

      // ثيم القائمة المنسدلة
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            isGlass
                ? AppColors.surfaceLight.withValues(alpha: 0.95)
                : AppColors.surfaceLight,
          ),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(isGlass ? 0 : 8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
          ),
        ),
      ),

      // ثيم الـ Expansion Panel
      expansionTileTheme: const ExpansionTileThemeData(
        textColor: AppColors.textPrimaryLight,
        collapsedTextColor: AppColors.textPrimaryLight,
        iconColor: AppColors.textSecondaryLight,
        collapsedIconColor: AppColors.textSecondaryLight,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),

      // ثيم شريط البحث
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          isGlass
              ? AppColors.surfaceLight.withValues(alpha: 0.8)
              : AppColors.surfaceLight,
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
        hintStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textHintLight,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  // ============= بناء الثيم الداكن =============

  // بناء الثيم الداكن (مشترك بين Classic و Glass)
  // يستخدم الـ builders من الملفات الفرعية لبناء كل مكون
  static ThemeData _buildDarkTheme({required bool isGlass}) {
    // اختيار قيم مختلفة حسب وضع التصميم
    final cardRadius =
        isGlass ? DesignTokens.radiusLarge : DesignTokens.radiusMedium;
    final cardElevation =
        isGlass ? DesignTokens.elevationNone : DesignTokens.elevationSmall;
    final buttonRadius =
        isGlass ? DesignTokens.radiusLarge : DesignTokens.radiusMedium;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // نظام الألوان للوضع الداكن
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.textPrimaryDark,
        primaryContainer: AppColors.primaryContainerDark,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        onSecondary: AppColors.textPrimaryDark,
        secondaryContainer: AppColors.secondaryContainerDark,
        onSecondaryContainer: AppColors.secondaryDark,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        // تلميح: ربط النص الثانوي للوضع المظلم لضمان وضوح الأوصاف
        onSurfaceVariant: AppColors.textSecondaryDark,
        // تلميح هام: تعديل الـ outline ليكون رمادياً فاتحاً (Slate 300) يناسب الأيقونات على الخلفية الزرقاء الداكنة
        outline: AppColors.textHintDark,
        outlineVariant: AppColors.borderDark, // مخصص للحدود في الوضع المظلم
        shadow: Colors.black26,
      ),

      // لون خلفية الشاشة في الوضع الداكن
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.backgroundDark,

      // المكونات المستخرجة من الملفات الفرعية
      appBarTheme: NavigationThemeBuilder.buildDarkAppBar(isGlass: isGlass),
      cardTheme: CardThemeBuilder.buildDark(
        isGlass: isGlass,
        cardRadius: cardRadius,
        cardElevation: cardElevation,
      ),
      elevatedButtonTheme: ButtonThemeBuilder.buildDarkElevated(
        isGlass: isGlass,
        buttonRadius: buttonRadius,
      ),
      outlinedButtonTheme:
          ButtonThemeBuilder.buildDarkOutlined(buttonRadius: buttonRadius),
      textButtonTheme: ButtonThemeBuilder.buildDarkText(),
      inputDecorationTheme: InputThemeBuilder.buildDark(
        isGlass: isGlass,
        cardRadius: cardRadius,
      ),
      dialogTheme: CardThemeBuilder.buildDarkDialog(isGlass: isGlass),
      drawerTheme: CardThemeBuilder.buildDarkDrawer(isGlass: isGlass),
      bottomNavigationBarTheme:
          NavigationThemeBuilder.buildDarkBottomNav(isGlass: isGlass),
      tabBarTheme: NavigationThemeBuilder.buildDarkTabBar(),
      bottomSheetTheme: CardThemeBuilder.buildDarkBottomSheet(isGlass: isGlass),

      // ثيم الأزرار - داكنة (مكونات بسيطة تبقى هنا)

      // ثيم الفواصل - داكنة
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 16,
      ),

      // ثيم عناصر القائمة - داكنة
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
        iconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      // ثيم الأيقونات - داكنة
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 24,
      ),

      // ثيم النصوص - داكن
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryDark,
          fontFamily: 'Cairo',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
          fontFamily: 'Cairo',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          fontFamily: 'Cairo',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryDark,
          fontFamily: 'Cairo',
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textHintDark,
          fontFamily: 'Cairo',
        ),
      ),

      // ثيم FloatingActionButton - داكن
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.backgroundDark,
        elevation: isGlass ? 0 : 4,
        // تلميح: مسحنا التقييد الدائري هنا أيضاً (CircleBorder) لتظهر الأزرار العائمة الممتدة بشكل مستطيل بدلاً من أن تُقص كنصف دائرة
      ),

      // ثيم Checkbox - داكن
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.backgroundDark),
        side: const BorderSide(color: AppColors.borderDark, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ثيم Radio - داكن
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.borderDark;
        }),
      ),

      // ثيم Switch - داكن
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.textHintDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark.withValues(alpha: 0.5);
          }
          return AppColors.borderDark;
        }),
      ),

      // ثيم ProgressIndicator - داكن
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryDark,
      ),

      // ثيم SnackBar - داكن
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ثيم Chip - داكن
      chipTheme: ChipThemeData(
        backgroundColor: isGlass
            ? AppColors.primaryContainerDark.withValues(alpha: 0.7)
            : AppColors.primaryContainerDark,
        labelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ثيم القائمة المنبثقة - داكن
      popupMenuTheme: PopupMenuThemeData(
        color: isGlass
            ? AppColors.surfaceDark.withValues(alpha: 0.95)
            : AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: isGlass ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 14,
            fontFamily: 'Cairo',
          ),
        ),
      ),

      // ثيم القائمة المنسدلة - داكن
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            isGlass
                ? AppColors.surfaceDark.withValues(alpha: 0.95)
                : AppColors.surfaceDark,
          ),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(isGlass ? 0 : 8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
          ),
        ),
      ),

      // ثيم الـ Expansion Panel - داكن
      expansionTileTheme: const ExpansionTileThemeData(
        textColor: AppColors.textPrimaryDark,
        collapsedTextColor: AppColors.textPrimaryDark,
        iconColor: AppColors.textSecondaryDark,
        collapsedIconColor: AppColors.textSecondaryDark,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),

      // ثيم شريط البحث - داكن
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          isGlass
              ? AppColors.surfaceDark.withValues(alpha: 0.8)
              : AppColors.surfaceDark,
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
        hintStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.textHintDark,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
