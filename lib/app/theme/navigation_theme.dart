import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

///  ثيمات التنقل والأشرطة — مستخرج من app_theme.dart لسهولة الصيانة
/// لا تغيير في المنطق أو الألوان أو القيم — فقط نقل الكود
class NavigationThemeBuilder {
  NavigationThemeBuilder._();

  // ================== AppBar ==================

  ///  ثيم شريط التطبيق — الوضع الفاتح
  static AppBarTheme buildLightAppBar({required bool isGlass}) {
    return AppBarTheme(
      elevation: isGlass ? 0 : 4,
      shadowColor:
          isGlass ? Colors.transparent : Colors.black.withValues(alpha: 0.15),
      centerTitle: true,
      backgroundColor: isGlass ? Colors.transparent : AppColors.primaryLight,
      foregroundColor: isGlass ? AppColors.primaryLightVariant : Colors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isGlass
          ? const SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarIconBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: isGlass ? AppColors.primaryLightVariant : Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      iconTheme: IconThemeData(
        color: isGlass ? AppColors.primaryLightVariant : Colors.white,
        size: 24,
      ),
    );
  }

  ///  ثيم شريط التطبيق — الوضع الداكن
  static AppBarTheme buildDarkAppBar({required bool isGlass}) {
    return AppBarTheme(
      elevation: isGlass ? 0 : 4,
      shadowColor:
          isGlass ? Colors.transparent : Colors.black.withValues(alpha: 0.3),
      centerTitle: true,
      backgroundColor: isGlass ? Colors.transparent : AppColors.primaryDark,
      foregroundColor: isGlass ? AppColors.textPrimaryDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isGlass
          ? const SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: isGlass ? AppColors.textPrimaryDark : Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      iconTheme: IconThemeData(
        color: isGlass ? AppColors.textPrimaryDark : Colors.white,
        size: 24,
      ),
    );
  }

  // ================== BottomNavigationBar ==================

  ///  ثيم شريط التنقل السفلي — فاتح
  static BottomNavigationBarThemeData buildLightBottomNav(
      {required bool isGlass}) {
    return BottomNavigationBarThemeData(
      backgroundColor:
          isGlass ? Colors.transparent : AppColors.bottomNavBackground,
      selectedItemColor: AppColors.bottomNavSelected,
      unselectedItemColor: AppColors.bottomNavUnselected,
      type: BottomNavigationBarType.fixed,
      elevation: isGlass ? 0 : 8,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedIconTheme: const IconThemeData(
        size: 28,
        color: AppColors.bottomNavSelected,
      ),
      unselectedIconTheme: const IconThemeData(
        size: 24,
        color: AppColors.bottomNavUnselected,
      ),
    );
  }

  ///  ثيم شريط التنقل السفلي — داكن
  static BottomNavigationBarThemeData buildDarkBottomNav(
      {required bool isGlass}) {
    return BottomNavigationBarThemeData(
      backgroundColor:
          isGlass ? Colors.transparent : AppColors.bottomNavBackgroundDark,
      selectedItemColor: AppColors.bottomNavSelectedDark,
      unselectedItemColor: AppColors.bottomNavUnselectedDark,
      type: BottomNavigationBarType.fixed,
      elevation: isGlass ? 0 : 8,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedIconTheme: const IconThemeData(
        size: 28,
        color: AppColors.bottomNavSelectedDark,
      ),
      unselectedIconTheme: const IconThemeData(
        size: 24,
        color: AppColors.bottomNavUnselectedDark,
      ),
    );
  }

  // ================== TabBar ==================

  ///  ثيم التبويبات — فاتح
  static TabBarThemeData buildLightTabBar() {
    return const TabBarThemeData(
      labelColor: AppColors.primaryLight,
      unselectedLabelColor: AppColors.textSecondaryLight,
      indicatorColor: AppColors.primaryLight,
      dividerColor: AppColors.dividerLight,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        fontFamily: 'Cairo',
      ),
    );
  }

  ///  ثيم التبويبات — داكن
  static TabBarThemeData buildDarkTabBar() {
    return const TabBarThemeData(
      labelColor: AppColors.primaryDark,
      unselectedLabelColor: AppColors.textSecondaryDark,
      indicatorColor: AppColors.primaryDark,
      dividerColor: AppColors.dividerDark,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        fontFamily: 'Cairo',
      ),
    );
  }
}
