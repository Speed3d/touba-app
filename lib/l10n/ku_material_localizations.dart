import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 📝 HINT AR: Flutter (`flutter_localizations`) لا يشحن ترجمات Material /
/// Cupertino / Widgets للغة الكردية (`ku`)، فيرمي «No MaterialLocalizations
/// found» في كل `Scaffold`/`AppBar`/`RefreshIndicator`/منتقي التاريخ...
///
/// الحل: نوفّر هذه الترجمات لـ`ku` بتفويضها لموارد **العربية** (`ar`) — الكردية
/// السورانية تُكتب بالخط العربي واتجاهها **RTL**، فالعربية أقرب تطابق (تسميات
/// «رجوع»/«إلغاء»، صيغ التاريخ، والاتجاه من اليمين لليسار).
///
/// تُسجَّل هذه المفوّضات **قبل** المفوّضات العامة في `localizationsDelegates`،
/// فتلتقط `ku` أولاً بينما تمرّ `ar`/`en` للمفوّضات العامة كالمعتاد.
class KuMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KuMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuMaterialLocalizationsDelegate old) => false;
}

class KuCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KuCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuCupertinoLocalizationsDelegate old) => false;
}

class KuWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const KuWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(KuWidgetsLocalizationsDelegate old) => false;
}
