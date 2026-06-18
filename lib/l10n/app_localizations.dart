import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'طوبة'**
  String get appTitle;

  /// No description provided for @tournaments.
  ///
  /// In ar, this message translates to:
  /// **'البطولات'**
  String get tournaments;

  /// No description provided for @teams.
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get teams;

  /// No description provided for @matches.
  ///
  /// In ar, this message translates to:
  /// **'المباريات'**
  String get matches;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @welcomeMessage.
  ///
  /// In ar, this message translates to:
  /// **'هلا بيك في منصة طوبة، ساحة الكور الشعبية'**
  String get welcomeMessage;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get error;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get editProfile;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف حسابك وبياناتك الشخصية نهائياً ولا يمكن التراجع.'**
  String get deleteAccountConfirm;

  /// No description provided for @createTeam.
  ///
  /// In ar, this message translates to:
  /// **'سجل فريقك'**
  String get createTeam;

  /// No description provided for @teamName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الفريق'**
  String get teamName;

  /// No description provided for @myTeam.
  ///
  /// In ar, this message translates to:
  /// **'فريقي'**
  String get myTeam;

  /// No description provided for @joinTeam.
  ///
  /// In ar, this message translates to:
  /// **'طلب انضمام للفريق'**
  String get joinTeam;

  /// No description provided for @manageTeam.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الفريق'**
  String get manageTeam;

  /// No description provided for @teamMembers.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة'**
  String get teamMembers;

  /// No description provided for @noTeamsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فرق مسجّلة بعد'**
  String get noTeamsYet;

  /// No description provided for @noTeamsHint.
  ///
  /// In ar, this message translates to:
  /// **'أسّس فريقك بزر «تأسيس فريق» أدناه'**
  String get noTeamsHint;

  /// No description provided for @noTeamsSearch.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فريق يطابق بحثك'**
  String get noTeamsSearch;

  /// No description provided for @foundTeams.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسجَّل أي فريق في المنصة بعد'**
  String get foundTeams;

  /// No description provided for @createTournament.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء بطولة'**
  String get createTournament;

  /// No description provided for @tournamentName.
  ///
  /// In ar, this message translates to:
  /// **'اسم البطولة'**
  String get tournamentName;

  /// No description provided for @tournamentType.
  ///
  /// In ar, this message translates to:
  /// **'نظام البطولة'**
  String get tournamentType;

  /// No description provided for @league.
  ///
  /// In ar, this message translates to:
  /// **'دوري (League)'**
  String get league;

  /// No description provided for @knockout.
  ///
  /// In ar, this message translates to:
  /// **'خروج المغلوب (Knockout)'**
  String get knockout;

  /// No description provided for @groups.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات (Groups)'**
  String get groups;

  /// No description provided for @noTournamentsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بطولات بعد'**
  String get noTournamentsYet;

  /// No description provided for @noTournamentsHint.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ أول بطولة بزر «إنشاء بطولة» أدناه'**
  String get noTournamentsHint;

  /// No description provided for @ongoingTournaments.
  ///
  /// In ar, this message translates to:
  /// **'بطولات جارية'**
  String get ongoingTournaments;

  /// No description provided for @otherTournaments.
  ///
  /// In ar, this message translates to:
  /// **'بطولات أخرى'**
  String get otherTournaments;

  /// No description provided for @ongoing.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get ongoing;

  /// No description provided for @addPlayer.
  ///
  /// In ar, this message translates to:
  /// **'ضيف لاعب'**
  String get addPlayer;

  /// No description provided for @playerCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة اللاعب'**
  String get playerCard;

  /// No description provided for @position.
  ///
  /// In ar, this message translates to:
  /// **'المركز'**
  String get position;

  /// No description provided for @goals.
  ///
  /// In ar, this message translates to:
  /// **'أهداف'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In ar, this message translates to:
  /// **'صناعة'**
  String get assists;

  /// No description provided for @yellowCards.
  ///
  /// In ar, this message translates to:
  /// **'بطاقات صفراء'**
  String get yellowCards;

  /// No description provided for @redCards.
  ///
  /// In ar, this message translates to:
  /// **'بطاقات حمراء'**
  String get redCards;

  /// No description provided for @matchesPlayed.
  ///
  /// In ar, this message translates to:
  /// **'مباريات'**
  String get matchesPlayed;

  /// No description provided for @rating.
  ///
  /// In ar, this message translates to:
  /// **'تقييم'**
  String get rating;

  /// No description provided for @preferredFoot.
  ///
  /// In ar, this message translates to:
  /// **'القدم المفضّلة'**
  String get preferredFoot;

  /// No description provided for @height.
  ///
  /// In ar, this message translates to:
  /// **'الطول'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get weight;

  /// No description provided for @claimByCode.
  ///
  /// In ar, this message translates to:
  /// **'ربط حسابي بكود'**
  String get claimByCode;

  /// No description provided for @enterScore.
  ///
  /// In ar, this message translates to:
  /// **'سجل النتيجة'**
  String get enterScore;

  /// No description provided for @standings.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get standings;

  /// No description provided for @result.
  ///
  /// In ar, this message translates to:
  /// **'النتيجة'**
  String get result;

  /// No description provided for @homeTeam.
  ///
  /// In ar, this message translates to:
  /// **'الفريق المضيف'**
  String get homeTeam;

  /// No description provided for @awayTeam.
  ///
  /// In ar, this message translates to:
  /// **'الفريق الضيف'**
  String get awayTeam;

  /// No description provided for @live.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get live;

  /// No description provided for @upcoming.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get upcoming;

  /// No description provided for @finished.
  ///
  /// In ar, this message translates to:
  /// **'انتهت'**
  String get finished;

  /// No description provided for @round.
  ///
  /// In ar, this message translates to:
  /// **'الجولة'**
  String get round;

  /// No description provided for @noLiveMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات جارية الآن'**
  String get noLiveMatches;

  /// No description provided for @noUpcomingMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات قادمة'**
  String get noUpcomingMatches;

  /// No description provided for @noFinishedMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات منتهية'**
  String get noFinishedMatches;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get noNotifications;

  /// No description provided for @noNotificationsHint.
  ///
  /// In ar, this message translates to:
  /// **'ستصلك إشعارات البطولات والفرق هنا'**
  String get noNotificationsHint;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @submitReport.
  ///
  /// In ar, this message translates to:
  /// **'تقديم بلاغ'**
  String get submitReport;

  /// No description provided for @reportReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب البلاغ'**
  String get reportReason;

  /// No description provided for @reportDescription.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إضافية'**
  String get reportDescription;

  /// No description provided for @offensiveContent.
  ///
  /// In ar, this message translates to:
  /// **'محتوى مسيء'**
  String get offensiveContent;

  /// No description provided for @inappropriateBehavior.
  ///
  /// In ar, this message translates to:
  /// **'سلوك غير لائق'**
  String get inappropriateBehavior;

  /// No description provided for @misleadingInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات مضلّلة'**
  String get misleadingInfo;

  /// No description provided for @otherReason.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get otherReason;

  /// No description provided for @reportSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال البلاغ بنجاح'**
  String get reportSubmitted;

  /// No description provided for @reportAboutPlayer.
  ///
  /// In ar, this message translates to:
  /// **'بلّغ عن هذا اللاعب'**
  String get reportAboutPlayer;

  /// No description provided for @reportAboutTeam.
  ///
  /// In ar, this message translates to:
  /// **'بلّغ عن هذا الفريق'**
  String get reportAboutTeam;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @appVersion.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق'**
  String get appVersion;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsConditions;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم الإدارة'**
  String get adminDashboard;

  /// No description provided for @manageLocations.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المواقع'**
  String get manageLocations;

  /// No description provided for @manageRoles.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الصلاحيات'**
  String get manageRoles;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'البلاغات'**
  String get reports;

  /// No description provided for @verifyTeams.
  ///
  /// In ar, this message translates to:
  /// **'توثيق الفرق'**
  String get verifyTeams;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً...'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
