import 'package:shared_preferences/shared_preferences.dart';

/// 📝 HINT AR: تخزين تفضيلات المستخدم محلياً (الثيم/اللغة/إكمال التعريف).
/// تُهيَّأ مرة في main() قبل runApp ليقرأها الـ Cubits فوراً عند الإقلاع.
class PreferencesService {
  static late SharedPreferences _prefs;

  static const _kIsDark = 'pref_is_dark';
  static const _kLocale = 'pref_locale';
  static const _kOnboardingSeen = 'pref_onboarding_seen';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // الثيم
  static bool get isDark => _prefs.getBool(_kIsDark) ?? false;
  static Future<void> setDark(bool value) => _prefs.setBool(_kIsDark, value);

  // اللغة (رمز اللغة: ar / en)
  static String get localeCode => _prefs.getString(_kLocale) ?? 'ar';
  static Future<void> setLocale(String code) =>
      _prefs.setString(_kLocale, code);

  // شاشات التعريف (Onboarding) — تُعرض مرة واحدة
  static bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  static Future<void> setOnboardingSeen() =>
      _prefs.setBool(_kOnboardingSeen, true);
}
