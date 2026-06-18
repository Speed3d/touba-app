import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/design_tokens.dart';
import '../../data/services/preferences_service.dart';

/// 📝 HINT AR: يحفظ تفضيل الثيم (فاتح/داكن) في PreferencesService فلا يضيع
/// عند إعادة التشغيل. يقرأ القيمة المحفوظة عند الإنشاء.
class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit()
      : super(AppTheme.getTheme(
          brightness:
              PreferencesService.isDark ? Brightness.dark : Brightness.light,
          designMode: DesignMode.classic,
        ));

  bool get isDark => state.brightness == Brightness.dark;

  void toggleTheme(Brightness brightness) {
    PreferencesService.setDark(brightness == Brightness.dark);
    emit(AppTheme.getTheme(
        brightness: brightness, designMode: DesignMode.classic));
  }

  /// تبديل سريع بين الفاتح والداكن.
  void toggle() =>
      toggleTheme(isDark ? Brightness.light : Brightness.dark);
}
