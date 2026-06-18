import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/preferences_service.dart';

/// 📝 HINT AR: يحفظ تفضيل اللغة في PreferencesService فلا يضيع عند إعادة التشغيل.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(Locale(PreferencesService.localeCode));

  void setLocale(Locale locale) {
    PreferencesService.setLocale(locale.languageCode);
    emit(locale);
  }
}
