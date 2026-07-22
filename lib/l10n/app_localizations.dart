import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';

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
    Locale('en'),
    Locale('ku')
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

  /// No description provided for @welcomeToTooba.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في طوبة'**
  String get welcomeToTooba;

  /// No description provided for @signInToContinue.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك للمتابعة'**
  String get signInToContinue;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال البريد الإلكتروني'**
  String get pleaseEnterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح'**
  String get invalidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال كلمة المرور'**
  String get pleaseEnterPassword;

  /// No description provided for @forgotPasswordQ.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPasswordQ;

  /// No description provided for @dontHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get dontHaveAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createNewAccount;

  /// No description provided for @continueAsVisitor.
  ///
  /// In ar, this message translates to:
  /// **'تخطي والمتابعة كزائر'**
  String get continueAsVisitor;

  /// No description provided for @joinToobaCommunity.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى مجتمع طوبة'**
  String get joinToobaCommunity;

  /// No description provided for @registerNowStartJourney.
  ///
  /// In ar, this message translates to:
  /// **'سجل الآن وابدأ رحلتك الكروية معنا'**
  String get registerNowStartJourney;

  /// No description provided for @pleaseEnterName.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسمك'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم الهاتف'**
  String get pleaseEnterPhone;

  /// No description provided for @phoneTooShort.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف قصير جداً'**
  String get phoneTooShort;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @accountType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب:'**
  String get accountType;

  /// No description provided for @rolePlayer.
  ///
  /// In ar, this message translates to:
  /// **'لاعب (البحث عن فرق ومباريات)'**
  String get rolePlayer;

  /// No description provided for @roleCaptain.
  ///
  /// In ar, this message translates to:
  /// **'كابتن (إنشاء وإدارة فريق)'**
  String get roleCaptain;

  /// No description provided for @roleReferee.
  ///
  /// In ar, this message translates to:
  /// **'حكم (إدارة المباريات)'**
  String get roleReferee;

  /// No description provided for @registerAccount.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحساب'**
  String get registerAccount;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني إذا كان مسجلاً لدينا.'**
  String get resetPasswordSent;

  /// No description provided for @enterEmailToReset.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني المسجل أدناه وسنرسل لك رابطاً لإنشاء كلمة مرور جديدة.'**
  String get enterEmailToReset;

  /// No description provided for @sendLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرابط'**
  String get sendLink;

  /// No description provided for @havingTroubleResetting.
  ///
  /// In ar, this message translates to:
  /// **'هل تواجه مشكلة؟ لا تعرف كيف تستعيد الحساب؟'**
  String get havingTroubleResetting;

  /// No description provided for @contactAdminComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تفعيل هذه الميزة قريباً لفتح المحادثة مع الإدارة.'**
  String get contactAdminComingSoon;

  /// No description provided for @contactAdmin.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الإدارة'**
  String get contactAdmin;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

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
  /// **'تأسيس فريق'**
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

  /// No description provided for @kurdish.
  ///
  /// In ar, this message translates to:
  /// **'كوردي'**
  String get kurdish;

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

  /// No description provided for @toubaFootball.
  ///
  /// In ar, this message translates to:
  /// **'TOUBA FOOTBALL'**
  String get toubaFootball;

  /// No description provided for @iraqiAmateurFootballPlatform.
  ///
  /// In ar, this message translates to:
  /// **'منصة كرة القدم الشعبية العراقية'**
  String get iraqiAmateurFootballPlatform;

  /// No description provided for @mySubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكي'**
  String get mySubscription;

  /// No description provided for @activeFreeTrial.
  ///
  /// In ar, this message translates to:
  /// **'تجربة مجانية فعّالة'**
  String get activeFreeTrial;

  /// No description provided for @activeSubscriber.
  ///
  /// In ar, this message translates to:
  /// **'مشترك فعّال'**
  String get activeSubscriber;

  /// No description provided for @notSubscribedActivate.
  ///
  /// In ar, this message translates to:
  /// **'غير مشترك — فعّل للتحدّيات'**
  String get notSubscribedActivate;

  /// No description provided for @myRefereeMatches.
  ///
  /// In ar, this message translates to:
  /// **'مبارياتي كحكم'**
  String get myRefereeMatches;

  /// No description provided for @assignedMatches.
  ///
  /// In ar, this message translates to:
  /// **'المباريات المعيّن لها'**
  String get assignedMatches;

  /// No description provided for @myRefereeProfile.
  ///
  /// In ar, this message translates to:
  /// **'صفحتي كحكم'**
  String get myRefereeProfile;

  /// No description provided for @publicProfileAndEdit.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة العامة + تعديل بياناتي'**
  String get publicProfileAndEdit;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @aboutAppAndPolicies.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق والسياسات'**
  String get aboutAppAndPolicies;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @deleteAccountSub.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي لحسابك وبياناتك الشخصية'**
  String get deleteAccountSub;

  /// No description provided for @youAreVisitor.
  ///
  /// In ar, this message translates to:
  /// **'أنت مسجّل كزائر'**
  String get youAreVisitor;

  /// No description provided for @generalError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get generalError;

  /// No description provided for @toobaPlatform.
  ///
  /// In ar, this message translates to:
  /// **'منصة طوبة ⚽'**
  String get toobaPlatform;

  /// No description provided for @teamCaptain.
  ///
  /// In ar, this message translates to:
  /// **'كابتن فريق'**
  String get teamCaptain;

  /// No description provided for @platformAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير المنصة'**
  String get platformAdmin;

  /// No description provided for @player.
  ///
  /// In ar, this message translates to:
  /// **'لاعب'**
  String get player;

  /// No description provided for @captainOfTeam.
  ///
  /// In ar, this message translates to:
  /// **'كابتن فريق '**
  String get captainOfTeam;

  /// No description provided for @captainNoTeam.
  ///
  /// In ar, this message translates to:
  /// **'كابتن (بلا فريق)'**
  String get captainNoTeam;

  /// No description provided for @playerWithTeam.
  ///
  /// In ar, this message translates to:
  /// **'لاعب مع فريق '**
  String get playerWithTeam;

  /// No description provided for @playerNoTeam.
  ///
  /// In ar, this message translates to:
  /// **'لاعب (بلا فريق)'**
  String get playerNoTeam;

  /// No description provided for @profileAndPlayerDetails.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي وتفاصيل اللاعب'**
  String get profileAndPlayerDetails;

  /// No description provided for @viewAndEditData.
  ///
  /// In ar, this message translates to:
  /// **'عرض وتعديل بياناتك'**
  String get viewAndEditData;

  /// No description provided for @registeredAsVisitor.
  ///
  /// In ar, this message translates to:
  /// **'أنت مسجّل كزائر'**
  String get registeredAsVisitor;

  /// No description provided for @loginOrRegister.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول / إنشاء حساب'**
  String get loginOrRegister;

  /// No description provided for @confirmLogoutMsg.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'**
  String get confirmLogoutMsg;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً'**
  String get deleteAccountPermanently;

  /// No description provided for @deleteAccountPermanentlyMsg.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف حسابك وبياناتك الشخصية نهائياً ولا يمكن التراجع.\n\nملاحظة: إن كنت كابتن فريق، احذف فريقك أو انقل الكابتنية أولاً.'**
  String get deleteAccountPermanentlyMsg;

  /// No description provided for @deletingAccount.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ حذف الحساب...'**
  String get deletingAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف حسابك'**
  String get accountDeleted;

  /// No description provided for @permanentDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get permanentDelete;

  /// No description provided for @captainDeleteError.
  ///
  /// In ar, this message translates to:
  /// **'أنت كابتن فريق — احذف فريقك أو انقل الكابتنية أولاً.'**
  String get captainDeleteError;

  /// No description provided for @deleteAccountError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حذف الحساب — حاول مرة أخرى لاحقاً.'**
  String get deleteAccountError;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطّي'**
  String get skip;

  /// No description provided for @formYourTeam.
  ///
  /// In ar, this message translates to:
  /// **'كوّن فريقك'**
  String get formYourTeam;

  /// No description provided for @formYourTeamDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل فريقك، أضف لاعبيك، وأدِر تشكيلتك من مكان واحد.'**
  String get formYourTeamDesc;

  /// No description provided for @organizeTournaments.
  ///
  /// In ar, this message translates to:
  /// **'نظّم بطولاتك'**
  String get organizeTournaments;

  /// No description provided for @organizeTournamentsDesc.
  ///
  /// In ar, this message translates to:
  /// **'دوريات وبطولات بجدول تلقائي وترتيب حيّ يتحدّث مع كل نتيجة.'**
  String get organizeTournamentsDesc;

  /// No description provided for @trackStats.
  ///
  /// In ar, this message translates to:
  /// **'تابع إحصائياتك'**
  String get trackStats;

  /// No description provided for @trackStatsDesc.
  ///
  /// In ar, this message translates to:
  /// **'أهداف، صناعة، بطاقات، وبطاقة لاعب لكل عضو — محسوبة آلياً.'**
  String get trackStatsDesc;

  /// No description provided for @startNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get startNow;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navTeam.
  ///
  /// In ar, this message translates to:
  /// **'الفريق'**
  String get navTeam;

  /// No description provided for @navChats.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get navChats;

  /// No description provided for @visitor.
  ///
  /// In ar, this message translates to:
  /// **'زائر'**
  String get visitor;

  /// No description provided for @welcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك، {userName}'**
  String welcomeUser(String userName);

  /// No description provided for @news.
  ///
  /// In ar, this message translates to:
  /// **'الأخبار'**
  String get news;

  /// No description provided for @myCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقتي'**
  String get myCard;

  /// No description provided for @mustLoginFirst.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول أولاً'**
  String get mustLoginFirst;

  /// No description provided for @noPlayerCardCurrently.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك بطاقة لاعب حالياً'**
  String get noPlayerCardCurrently;

  /// No description provided for @playerNotFound.
  ///
  /// In ar, this message translates to:
  /// **'اللاعب غير موجود'**
  String get playerNotFound;

  /// No description provided for @errorFetchingCard.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء جلب البطاقة'**
  String get errorFetchingCard;

  /// No description provided for @urgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجل'**
  String get urgent;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل ›'**
  String get viewAll;

  /// No description provided for @baghdadMajorTournament.
  ///
  /// In ar, this message translates to:
  /// **'بطولة بغداد الكبرى'**
  String get baghdadMajorTournament;

  /// No description provided for @localYouthLeague.
  ///
  /// In ar, this message translates to:
  /// **'دوري الشباب المحلي'**
  String get localYouthLeague;

  /// No description provided for @round3of4_8teams.
  ///
  /// In ar, this message translates to:
  /// **'الجولة ٣ من ٤ · ٨ فرق'**
  String get round3of4_8teams;

  /// No description provided for @round1of6_6teams.
  ///
  /// In ar, this message translates to:
  /// **'الجولة ١ من ٦ · ٦ فرق'**
  String get round1of6_6teams;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً...'**
  String get comingSoon;

  /// No description provided for @latestNews.
  ///
  /// In ar, this message translates to:
  /// **'آخر الأخبار'**
  String get latestNews;

  /// No description provided for @noNewsCurrently.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أخبار حالياً'**
  String get noNewsCurrently;

  /// No description provided for @loginToLike.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لتتمكن من الإعجاب'**
  String get loginToLike;

  /// No description provided for @errorLiking.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الإعجاب'**
  String get errorLiking;

  /// No description provided for @viaToobaApp.
  ///
  /// In ar, this message translates to:
  /// **'عبر تطبيق طوبة للمحترفين'**
  String get viaToobaApp;

  /// No description provided for @featured.
  ///
  /// In ar, this message translates to:
  /// **'الأبرز'**
  String get featured;

  /// No description provided for @justNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} دقيقة'**
  String minutesAgo(int count);

  /// No description provided for @oneHourAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ 1 ساعة'**
  String get oneHourAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} ساعات'**
  String hoursAgo(int count);

  /// No description provided for @oneDayAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ 1 يوم'**
  String get oneDayAgo;

  /// No description provided for @daysAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} أيام'**
  String daysAgo(int count);

  /// No description provided for @likeCount.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب ({count})'**
  String likeCount(int count);

  /// No description provided for @shareCount.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة ({count})'**
  String shareCount(int count);

  /// No description provided for @errorOpeningLink.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الرابط'**
  String get errorOpeningLink;

  /// No description provided for @bannerDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الإعلان'**
  String get bannerDetails;

  /// No description provided for @contactCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get contactCall;

  /// No description provided for @contactWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get contactWhatsapp;

  /// No description provided for @contactFacebook.
  ///
  /// In ar, this message translates to:
  /// **'فيسبوك'**
  String get contactFacebook;

  /// No description provided for @contactInstagram.
  ///
  /// In ar, this message translates to:
  /// **'إنستغرام'**
  String get contactInstagram;

  /// No description provided for @contactWebsite.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get contactWebsite;

  /// No description provided for @readAll.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الكل'**
  String get readAll;

  /// No description provided for @errorPrefix.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {message}'**
  String errorPrefix(String message);

  /// No description provided for @noNotificationsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات بعد'**
  String get noNotificationsYet;

  /// No description provided for @challengeChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة التحدّي'**
  String get challengeChat;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterday;

  /// No description provided for @chooseReadyAvatar.
  ///
  /// In ar, this message translates to:
  /// **'اختيار أفاتار جاهز'**
  String get chooseReadyAvatar;

  /// No description provided for @chooseFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get takePhoto;

  /// No description provided for @chooseReadyImage.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة جاهزة'**
  String get chooseReadyImage;

  /// No description provided for @chooseYourAvatar.
  ///
  /// In ar, this message translates to:
  /// **'اختر الأفاتار الذي يناسبك'**
  String get chooseYourAvatar;

  /// No description provided for @confirmImage.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الصورة'**
  String get confirmImage;

  /// No description provided for @footRight.
  ///
  /// In ar, this message translates to:
  /// **'يمنى'**
  String get footRight;

  /// No description provided for @footLeft.
  ///
  /// In ar, this message translates to:
  /// **'يسرى'**
  String get footLeft;

  /// No description provided for @footBoth.
  ///
  /// In ar, this message translates to:
  /// **'كلتاهما'**
  String get footBoth;

  /// No description provided for @failedToLoadPlayer.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل بيانات اللاعب'**
  String get failedToLoadPlayer;

  /// No description provided for @chooseBirthDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخ الميلاد'**
  String get chooseBirthDate;

  /// No description provided for @detailsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تفاصيلك'**
  String get detailsSaved;

  /// No description provided for @failedToSaveDetails.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التفاصيل'**
  String get failedToSaveDetails;

  /// No description provided for @playerDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اللاعب'**
  String get playerDetails;

  /// No description provided for @heightCm.
  ///
  /// In ar, this message translates to:
  /// **'الطول (سم)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In ar, this message translates to:
  /// **'الوزن (كغم)'**
  String get weightKg;

  /// No description provided for @birthDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get birthDate;

  /// No description provided for @notSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSpecified;

  /// No description provided for @ageYears.
  ///
  /// In ar, this message translates to:
  /// **'العمر {age} سنة'**
  String ageYears(int age);

  /// No description provided for @bioTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبذة عنك'**
  String get bioTitle;

  /// No description provided for @bioHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب نبذة مختصرة عن أسلوب لعبك...'**
  String get bioHint;

  /// No description provided for @yourGallery.
  ///
  /// In ar, this message translates to:
  /// **'معرض صورك ({count}/{max})'**
  String yourGallery(int count, int max);

  /// No description provided for @saveDetails.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التفاصيل'**
  String get saveDetails;

  /// No description provided for @referee.
  ///
  /// In ar, this message translates to:
  /// **'حكم'**
  String get referee;

  /// No description provided for @refereeProfile.
  ///
  /// In ar, this message translates to:
  /// **'صفحة الحكم'**
  String get refereeProfile;

  /// No description provided for @editMyData.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بياناتي'**
  String get editMyData;

  /// No description provided for @matchesManaged.
  ///
  /// In ar, this message translates to:
  /// **'مباريات أدارها'**
  String get matchesManaged;

  /// No description provided for @averageRating.
  ///
  /// In ar, this message translates to:
  /// **'متوسط التقييم'**
  String get averageRating;

  /// No description provided for @bioLabel.
  ///
  /// In ar, this message translates to:
  /// **'نبذة'**
  String get bioLabel;

  /// No description provided for @matchesList.
  ///
  /// In ar, this message translates to:
  /// **'المباريات'**
  String get matchesList;

  /// No description provided for @noMatchesManaged.
  ///
  /// In ar, this message translates to:
  /// **'لم يُدِر أي مباراة بعد'**
  String get noMatchesManaged;

  /// No description provided for @matchLive.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get matchLive;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @bioExperience.
  ///
  /// In ar, this message translates to:
  /// **'نبذة/خبرة'**
  String get bioExperience;

  /// No description provided for @dataSavedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ بياناتك'**
  String get dataSavedSuccessfully;

  /// No description provided for @failedToSave.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ'**
  String get failedToSave;

  /// No description provided for @matchesTab.
  ///
  /// In ar, this message translates to:
  /// **'مباريات'**
  String get matchesTab;

  /// No description provided for @tournamentsTab.
  ///
  /// In ar, this message translates to:
  /// **'بطولات'**
  String get tournamentsTab;

  /// No description provided for @liveTab.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get liveTab;

  /// No description provided for @upcomingTab.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get upcomingTab;

  /// No description provided for @finishedTab.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get finishedTab;

  /// No description provided for @failedToLoadTournaments.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل البطولات'**
  String get failedToLoadTournaments;

  /// No description provided for @noTournaments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بطولات'**
  String get noTournaments;

  /// No description provided for @noTournamentsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على أي بطولات حالياً'**
  String get noTournamentsFound;

  /// No description provided for @upcomingTournaments.
  ///
  /// In ar, this message translates to:
  /// **'بطولات قادمة'**
  String get upcomingTournaments;

  /// No description provided for @finishedTournaments.
  ///
  /// In ar, this message translates to:
  /// **'بطولات منتهية'**
  String get finishedTournaments;

  /// No description provided for @statusFinished.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get statusFinished;

  /// No description provided for @statusOngoing.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get statusOngoing;

  /// No description provided for @teamsCountText.
  ///
  /// In ar, this message translates to:
  /// **'{count} فريق'**
  String teamsCountText(int count);

  /// No description provided for @noMatchesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات'**
  String get noMatchesFound;

  /// No description provided for @errorTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get errorTitle;

  /// No description provided for @matchDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المباراة'**
  String get matchDetails;

  /// No description provided for @detailsTab.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل'**
  String get detailsTab;

  /// No description provided for @formationsTab.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة الفريقين'**
  String get formationsTab;

  /// No description provided for @roundX.
  ///
  /// In ar, this message translates to:
  /// **'الجولة {round}'**
  String roundX(String round);

  /// No description provided for @refereeNameX.
  ///
  /// In ar, this message translates to:
  /// **'الحكم: {name}'**
  String refereeNameX(String name);

  /// No description provided for @halfX.
  ///
  /// In ar, this message translates to:
  /// **'ش{half}'**
  String halfX(String half);

  /// No description provided for @startMatch.
  ///
  /// In ar, this message translates to:
  /// **'بدأ المباراة'**
  String get startMatch;

  /// No description provided for @liveMatchControl.
  ///
  /// In ar, this message translates to:
  /// **'تحكّم المباراة الحيّة'**
  String get liveMatchControl;

  /// No description provided for @endHalfX.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء الشوط {half}'**
  String endHalfX(int half);

  /// No description provided for @startHalfX.
  ///
  /// In ar, this message translates to:
  /// **'بدأ الشوط {half}'**
  String startHalfX(int half);

  /// No description provided for @endAndConfirmResult.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء وتأكيد النتيجة'**
  String get endAndConfirmResult;

  /// No description provided for @confirmHalfResultX.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد نتيجة الشوط {half}'**
  String confirmHalfResultX(int half);

  /// No description provided for @halfResultText.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة الشوط {half}: {homeName} {homeScore} - {awayScore} {awayName}'**
  String halfResultText(
      int half, String homeName, int homeScore, int awayScore, String awayName);

  /// No description provided for @matchInProgress.
  ///
  /// In ar, this message translates to:
  /// **'المباراة جارية الآن'**
  String get matchInProgress;

  /// No description provided for @matchNotStarted.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ المباراة بعد'**
  String get matchNotStarted;

  /// No description provided for @ratedThisReferee.
  ///
  /// In ar, this message translates to:
  /// **'قيّمت هذا الحكم'**
  String get ratedThisReferee;

  /// No description provided for @rateRefereePerformance.
  ///
  /// In ar, this message translates to:
  /// **'قيّم أداء الحكم'**
  String get rateRefereePerformance;

  /// No description provided for @loginToRate.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للتقييم'**
  String get loginToRate;

  /// No description provided for @rateReferee.
  ///
  /// In ar, this message translates to:
  /// **'تقييم الحكم'**
  String get rateReferee;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @thanksForRating.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لتقييمك!'**
  String get thanksForRating;

  /// No description provided for @failedToSendRating.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال التقييم'**
  String get failedToSendRating;

  /// No description provided for @formationForThisMatch.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة هذه المباراة'**
  String get formationForThisMatch;

  /// No description provided for @formationWithPlan.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة هذه المباراة • خطة {plan}'**
  String formationWithPlan(String plan);

  /// No description provided for @currentTeamFormationNotSaved.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة الحالية للفريق (لم تُحفظ بعد لهذه المباراة)'**
  String get currentTeamFormationNotSaved;

  /// No description provided for @shareFormation.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة التشكيلة'**
  String get shareFormation;

  /// No description provided for @formationOfTeam.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة {teamName}'**
  String formationOfTeam(String teamName);

  /// No description provided for @planX.
  ///
  /// In ar, this message translates to:
  /// **'خطة {plan}'**
  String planX(String plan);

  /// No description provided for @noEventsRecorded.
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجَّل أحداث لهذه المباراة'**
  String get noEventsRecorded;

  /// No description provided for @versus.
  ///
  /// In ar, this message translates to:
  /// **'ضد'**
  String get versus;

  /// No description provided for @actionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ الإجراء'**
  String get actionFailed;

  /// No description provided for @loginFirst.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول أولاً'**
  String get loginFirst;

  /// No description provided for @reportThisPlayer.
  ///
  /// In ar, this message translates to:
  /// **'بلّغ عن هذا اللاعب'**
  String get reportThisPlayer;

  /// No description provided for @verifiedAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب موثّق'**
  String get verifiedAccount;

  /// No description provided for @technicalDetails.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل الفنية'**
  String get technicalDetails;

  /// No description provided for @age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get age;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @yearsOldX.
  ///
  /// In ar, this message translates to:
  /// **'{years} سنة'**
  String yearsOldX(String years);

  /// No description provided for @cmX.
  ///
  /// In ar, this message translates to:
  /// **'{cm} سم'**
  String cmX(String cm);

  /// No description provided for @kgX.
  ///
  /// In ar, this message translates to:
  /// **'{kg} كجم'**
  String kgX(String kg);

  /// No description provided for @statusInjured.
  ///
  /// In ar, this message translates to:
  /// **'مصاب'**
  String get statusInjured;

  /// No description provided for @statusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get statusSuspended;

  /// No description provided for @statusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get statusActive;

  /// No description provided for @gallery.
  ///
  /// In ar, this message translates to:
  /// **'معرض الصور'**
  String get gallery;

  /// No description provided for @noMatchesAssignedToYou.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات معيّنة لك'**
  String get noMatchesAssignedToYou;

  /// No description provided for @tournamentOrganizerAssignsMatches.
  ///
  /// In ar, this message translates to:
  /// **'يعيّنك منظّم البطولة على المباريات'**
  String get tournamentOrganizerAssignsMatches;

  /// No description provided for @unspecifiedDate.
  ///
  /// In ar, this message translates to:
  /// **'موعد غير محدد'**
  String get unspecifiedDate;

  /// No description provided for @tournamentScheme.
  ///
  /// In ar, this message translates to:
  /// **'مخطط البطولة'**
  String get tournamentScheme;

  /// No description provided for @standingsTable.
  ///
  /// In ar, this message translates to:
  /// **'جدول الترتيب'**
  String get standingsTable;

  /// No description provided for @knockoutTreeUpToCup.
  ///
  /// In ar, this message translates to:
  /// **'شجرة المواجهات حتى الكأس'**
  String get knockoutTreeUpToCup;

  /// No description provided for @teamsRankingAndPoints.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الفرق ونقاطها'**
  String get teamsRankingAndPoints;

  /// No description provided for @liveMatchesTab.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get liveMatchesTab;

  /// No description provided for @upcomingMatchesTab.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get upcomingMatchesTab;

  /// No description provided for @finishedMatchesTab.
  ///
  /// In ar, this message translates to:
  /// **'انتهت'**
  String get finishedMatchesTab;

  /// No description provided for @failedToLoadMatches.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المباريات'**
  String get failedToLoadMatches;

  /// No description provided for @noLiveMatchesNow.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات جارية الآن'**
  String get noLiveMatchesNow;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غداً'**
  String get tomorrow;

  /// No description provided for @todayAtTime.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {time}'**
  String todayAtTime(String time);

  /// No description provided for @tomorrowAtTime.
  ///
  /// In ar, this message translates to:
  /// **'غداً {time}'**
  String tomorrowAtTime(String time);

  /// No description provided for @userNotRegistered.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم غير مسجّل'**
  String get userNotRegistered;

  /// No description provided for @teamsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get teamsTitle;

  /// No description provided for @myTeamTab.
  ///
  /// In ar, this message translates to:
  /// **'فريقي'**
  String get myTeamTab;

  /// No description provided for @popularTeamsTab.
  ///
  /// In ar, this message translates to:
  /// **'الفرق الشعبية'**
  String get popularTeamsTab;

  /// No description provided for @yourPitchAwaits.
  ///
  /// In ar, this message translates to:
  /// **'ملعبك ينتظرك'**
  String get yourPitchAwaits;

  /// No description provided for @dontHaveTeamYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك فريق بعد؟'**
  String get dontHaveTeamYet;

  /// No description provided for @createTeamSubtitleCaptain.
  ///
  /// In ar, this message translates to:
  /// **'أسّس فريقك وانضم للبطولات المحلية\nفي منطقتك الآن'**
  String get createTeamSubtitleCaptain;

  /// No description provided for @joinExistingTeamSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى فريق موجود وانطلق نحو\nالبطولات المحلية'**
  String get joinExistingTeamSubtitle;

  /// No description provided for @createYourTeamNow.
  ///
  /// In ar, this message translates to:
  /// **'⚽ أسّس فريقك الآن'**
  String get createYourTeamNow;

  /// No description provided for @joinExistingTeamBtn.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى فريق موجود'**
  String get joinExistingTeamBtn;

  /// No description provided for @playerCountX.
  ///
  /// In ar, this message translates to:
  /// **'{count} لاعب'**
  String playerCountX(String count);

  /// No description provided for @viewTeam.
  ///
  /// In ar, this message translates to:
  /// **'عرض الفريق'**
  String get viewTeam;

  /// No description provided for @challengesTab.
  ///
  /// In ar, this message translates to:
  /// **'التحديات'**
  String get challengesTab;

  /// No description provided for @roster.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة'**
  String get roster;

  /// No description provided for @yourExitRequestPending.
  ///
  /// In ar, this message translates to:
  /// **'طلب خروجك قيد مراجعة الكابتن'**
  String get yourExitRequestPending;

  /// No description provided for @yourRequestEscalated.
  ///
  /// In ar, this message translates to:
  /// **'طلبك مُصعّد للإدارة — بانتظار القرار'**
  String get yourRequestEscalated;

  /// No description provided for @captainRejectedYourRequest.
  ///
  /// In ar, this message translates to:
  /// **'رفض كابتنك طلب الخروج'**
  String get captainRejectedYourRequest;

  /// No description provided for @escalateRequestToAdmin.
  ///
  /// In ar, this message translates to:
  /// **'تصعيد الطلب للإدارة'**
  String get escalateRequestToAdmin;

  /// No description provided for @requestEscalatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تصعيد طلبك للإدارة'**
  String get requestEscalatedSuccess;

  /// No description provided for @failedToEscalate.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التصعيد'**
  String get failedToEscalate;

  /// No description provided for @searchForTeam.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن فريق...'**
  String get searchForTeam;

  /// No description provided for @failedToLoadTeams.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الفرق'**
  String get failedToLoadTeams;

  /// No description provided for @noTeamsRegisteredYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فرق مسجّلة بعد'**
  String get noTeamsRegisteredYet;

  /// No description provided for @noTeamsRegisteredInPlatform.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسجَّل أي فريق في المنصة بعد'**
  String get noTeamsRegisteredInPlatform;

  /// No description provided for @noResultsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResultsFound;

  /// No description provided for @noTeamMatchesX.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فريق يطابق \"{query}\"'**
  String noTeamMatchesX(String query);

  /// No description provided for @otherTeamsLabel.
  ///
  /// In ar, this message translates to:
  /// **'فرق أخرى'**
  String get otherTeamsLabel;

  /// No description provided for @noOtherTeamsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فرق أخرى بعد'**
  String get noOtherTeamsYet;

  /// No description provided for @playedCount.
  ///
  /// In ar, this message translates to:
  /// **'لعب'**
  String get playedCount;

  /// No description provided for @winsCount.
  ///
  /// In ar, this message translates to:
  /// **'فاز'**
  String get winsCount;

  /// No description provided for @tournamentsCount.
  ///
  /// In ar, this message translates to:
  /// **'بطولات'**
  String get tournamentsCount;

  /// No description provided for @cityAndAreaX.
  ///
  /// In ar, this message translates to:
  /// **'{city} • {area}'**
  String cityAndAreaX(String city, String area);

  /// No description provided for @pleaseSelectCity.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار المحافظة'**
  String get pleaseSelectCity;

  /// No description provided for @selectTwoTeamsAtLeast.
  ///
  /// In ar, this message translates to:
  /// **'اختر فريقين على الأقل'**
  String get selectTwoTeamsAtLeast;

  /// No description provided for @teamHasNotEnoughStarters.
  ///
  /// In ar, this message translates to:
  /// **'فريق «{team}» يملك {starters} أساسيين فقط — المطلوب {format}'**
  String teamHasNotEnoughStarters(String team, String starters, String format);

  /// No description provided for @failedToValidateTeamLineups.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقّق من تشكيلات الفرق'**
  String get failedToValidateTeamLineups;

  /// No description provided for @tournamentStartDateHelp.
  ///
  /// In ar, this message translates to:
  /// **'موعد بداية البطولة'**
  String get tournamentStartDateHelp;

  /// No description provided for @tournamentCreatedAndScheduleGenerated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء البطولة وتوليد الجدول!'**
  String get tournamentCreatedAndScheduleGenerated;

  /// No description provided for @createTournamentTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء بطولة'**
  String get createTournamentTitle;

  /// No description provided for @tournamentImageOptional.
  ///
  /// In ar, this message translates to:
  /// **'صورة البطولة (اختياري)'**
  String get tournamentImageOptional;

  /// No description provided for @tournamentNameInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم البطولة'**
  String get tournamentNameInputLabel;

  /// No description provided for @pleaseEnterTournamentName.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم البطولة'**
  String get pleaseEnterTournamentName;

  /// No description provided for @tournamentStartDateOptional.
  ///
  /// In ar, this message translates to:
  /// **'موعد بداية البطولة (اختياري)'**
  String get tournamentStartDateOptional;

  /// No description provided for @systemWillScheduleMatches.
  ///
  /// In ar, this message translates to:
  /// **'يُجدول النظام المباريات تلقائياً'**
  String get systemWillScheduleMatches;

  /// No description provided for @schedulingMode.
  ///
  /// In ar, this message translates to:
  /// **'نمط الجدولة'**
  String get schedulingMode;

  /// No description provided for @intervalBetweenRounds.
  ///
  /// In ar, this message translates to:
  /// **'فاصل بين الجولات'**
  String get intervalBetweenRounds;

  /// No description provided for @fixedDailyTime.
  ///
  /// In ar, this message translates to:
  /// **'توقيت يومي ثابت'**
  String get fixedDailyTime;

  /// No description provided for @roundsIntervalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفاصل بين الجولات'**
  String get roundsIntervalLabel;

  /// No description provided for @daily.
  ///
  /// In ar, this message translates to:
  /// **'يومياً'**
  String get daily;

  /// No description provided for @everyThreeDays.
  ///
  /// In ar, this message translates to:
  /// **'كل 3 أيام'**
  String get everyThreeDays;

  /// No description provided for @weekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعياً'**
  String get weekly;

  /// No description provided for @everyTwoWeeks.
  ///
  /// In ar, this message translates to:
  /// **'كل أسبوعين'**
  String get everyTwoWeeks;

  /// No description provided for @matchesPerDay.
  ///
  /// In ar, this message translates to:
  /// **'عدد المباريات في اليوم'**
  String get matchesPerDay;

  /// No description provided for @oneMatch.
  ///
  /// In ar, this message translates to:
  /// **'مباراة واحدة'**
  String get oneMatch;

  /// No description provided for @twoMatches.
  ///
  /// In ar, this message translates to:
  /// **'مباراتان'**
  String get twoMatches;

  /// No description provided for @threeMatches.
  ///
  /// In ar, this message translates to:
  /// **'ثلاث مباريات'**
  String get threeMatches;

  /// No description provided for @intervalBetweenDailyMatches.
  ///
  /// In ar, this message translates to:
  /// **'الفاصل بين مباريات اليوم'**
  String get intervalBetweenDailyMatches;

  /// No description provided for @oneHour.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get oneHour;

  /// No description provided for @oneAndHalfHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعة ونصف'**
  String get oneAndHalfHours;

  /// No description provided for @twoHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعتان'**
  String get twoHours;

  /// No description provided for @halfDuration.
  ///
  /// In ar, this message translates to:
  /// **'مدّة الشوط'**
  String get halfDuration;

  /// No description provided for @thirtyMinutes.
  ///
  /// In ar, this message translates to:
  /// **'30 دقيقة'**
  String get thirtyMinutes;

  /// No description provided for @fortyFiveMinutes.
  ///
  /// In ar, this message translates to:
  /// **'45 دقيقة'**
  String get fortyFiveMinutes;

  /// No description provided for @halvesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأشواط'**
  String get halvesCount;

  /// No description provided for @oneHalf.
  ///
  /// In ar, this message translates to:
  /// **'شوط واحد'**
  String get oneHalf;

  /// No description provided for @twoHalves.
  ///
  /// In ar, this message translates to:
  /// **'شوطان'**
  String get twoHalves;

  /// No description provided for @cityLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get cityLabel;

  /// No description provided for @tournamentSystem.
  ///
  /// In ar, this message translates to:
  /// **'نظام البطولة'**
  String get tournamentSystem;

  /// No description provided for @leagueSystem.
  ///
  /// In ar, this message translates to:
  /// **'دوري (League)'**
  String get leagueSystem;

  /// No description provided for @knockoutSystem.
  ///
  /// In ar, this message translates to:
  /// **'خروج المغلوب (Knockout)'**
  String get knockoutSystem;

  /// No description provided for @groupsSystem.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات (Groups)'**
  String get groupsSystem;

  /// No description provided for @startersCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد اللاعبين الأساسيين'**
  String get startersCount;

  /// No description provided for @sixASide.
  ///
  /// In ar, this message translates to:
  /// **'سداسي (6 لاعبين)'**
  String get sixASide;

  /// No description provided for @eightASide.
  ///
  /// In ar, this message translates to:
  /// **'ثماني (8 لاعبين)'**
  String get eightASide;

  /// No description provided for @elevenASide.
  ///
  /// In ar, this message translates to:
  /// **'11 لاعب'**
  String get elevenASide;

  /// No description provided for @homeAndAwaySystem.
  ///
  /// In ar, this message translates to:
  /// **'نظام الذهاب والإياب'**
  String get homeAndAwaySystem;

  /// No description provided for @homeAndAwaySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تُلعب كل مواجهة مرتين'**
  String get homeAndAwaySubtitle;

  /// No description provided for @freeTournamentOption.
  ///
  /// In ar, this message translates to:
  /// **'بطولة مجانية'**
  String get freeTournamentOption;

  /// No description provided for @freeTournamentSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يستطيع الأدمن إضافة أي فريق'**
  String get freeTournamentSubtitle;

  /// No description provided for @paidTournamentSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'باشتراك — يُضاف الفريق بعد دفع الرسوم'**
  String get paidTournamentSubtitle;

  /// No description provided for @entryFeesOrContact.
  ///
  /// In ar, this message translates to:
  /// **'رسوم/تواصل الدخول (يُعرض على البطولة)'**
  String get entryFeesOrContact;

  /// No description provided for @knockoutGenerationMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة توليد المباريات الإقصائية'**
  String get knockoutGenerationMethod;

  /// No description provided for @generateFullTree.
  ///
  /// In ar, this message translates to:
  /// **'توليد كامل الشجرة مقدماً (TBD)'**
  String get generateFullTree;

  /// No description provided for @generateRoundByRound.
  ///
  /// In ar, this message translates to:
  /// **'توليد جولة بجولة'**
  String get generateRoundByRound;

  /// No description provided for @groupsCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد المجموعات'**
  String get groupsCountLabel;

  /// No description provided for @qualifiersPerGroup.
  ///
  /// In ar, this message translates to:
  /// **'المتأهّلون من كل مجموعة'**
  String get qualifiersPerGroup;

  /// No description provided for @firstOnly.
  ///
  /// In ar, this message translates to:
  /// **'الأول فقط'**
  String get firstOnly;

  /// No description provided for @firstAndSecond.
  ///
  /// In ar, this message translates to:
  /// **'الأول والثاني'**
  String get firstAndSecond;

  /// No description provided for @firstSecondThird.
  ///
  /// In ar, this message translates to:
  /// **'الأول والثاني والثالث'**
  String get firstSecondThird;

  /// No description provided for @tieBreakRules.
  ///
  /// In ar, this message translates to:
  /// **'حسم التعادل (الأدوار الإقصائية)'**
  String get tieBreakRules;

  /// No description provided for @extraTimeThenPenalties.
  ///
  /// In ar, this message translates to:
  /// **'أشواط إضافية ثم جزاءات'**
  String get extraTimeThenPenalties;

  /// No description provided for @straightToPenalties.
  ///
  /// In ar, this message translates to:
  /// **'جزاءات مباشرة'**
  String get straightToPenalties;

  /// No description provided for @participatingTeamsCountX.
  ///
  /// In ar, this message translates to:
  /// **'الفرق المشاركة ({count})'**
  String participatingTeamsCountX(String count);

  /// No description provided for @noTeamsYetCreateFirst.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فرق بعد — أنشئ فرقاً أولاً من تبويب الفرق'**
  String get noTeamsYetCreateFirst;

  /// No description provided for @cityAndCaptainX.
  ///
  /// In ar, this message translates to:
  /// **'{city} • كابتن: {name}'**
  String cityAndCaptainX(String city, String name);

  /// No description provided for @refereesCountX.
  ///
  /// In ar, this message translates to:
  /// **'الحكّام ({count})'**
  String refereesCountX(String count);

  /// No description provided for @systemDistributesRefereesRandomly.
  ///
  /// In ar, this message translates to:
  /// **'يوزّعهم النظام عشوائياً على المباريات دون تكرار حكم بنفس الموعد.'**
  String get systemDistributesRefereesRandomly;

  /// No description provided for @noRefereesAdminMustGrant.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حكّام — يمنح الأدمن صفة الحكم للمستخدمين'**
  String get noRefereesAdminMustGrant;

  /// No description provided for @createTournamentAndGenerateScheduleBtn.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء البطولة وتوليد الجدول'**
  String get createTournamentAndGenerateScheduleBtn;

  /// No description provided for @selectAdvancedTeamNoDrawInKnockout.
  ///
  /// In ar, this message translates to:
  /// **'حدّد الفريق المتأهّل (لا يجوز تعادل في دور إقصائي)'**
  String get selectAdvancedTeamNoDrawInKnockout;

  /// No description provided for @enterResultTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدخال النتيجة'**
  String get enterResultTitle;

  /// No description provided for @saveAndConfirmResultBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وتأكيد النتيجة'**
  String get saveAndConfirmResultBtn;

  /// No description provided for @resultCalculatedAutomatically.
  ///
  /// In ar, this message translates to:
  /// **'النتيجة تُحسب تلقائياً من الأهداف. قاعدة: إنذاران = طرد.'**
  String get resultCalculatedAutomatically;

  /// No description provided for @tieBreakKnockoutStage.
  ///
  /// In ar, this message translates to:
  /// **'حسم التعادل (دور إقصائي)'**
  String get tieBreakKnockoutStage;

  /// No description provided for @tieBreakMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحسم:'**
  String get tieBreakMethod;

  /// No description provided for @penaltyShootoutOptional.
  ///
  /// In ar, this message translates to:
  /// **'ركلات الترجيح (اختياري):'**
  String get penaltyShootoutOptional;

  /// No description provided for @advancedTeamToNextRound.
  ///
  /// In ar, this message translates to:
  /// **'الفريق المتأهّل للدور التالي:'**
  String get advancedTeamToNextRound;

  /// No description provided for @noPlayersRegisteredInTeam.
  ///
  /// In ar, this message translates to:
  /// **'لا لاعبون مسجّلون في هذا الفريق'**
  String get noPlayersRegisteredInTeam;

  /// No description provided for @goalEvent.
  ///
  /// In ar, this message translates to:
  /// **'هدف'**
  String get goalEvent;

  /// No description provided for @assistEvent.
  ///
  /// In ar, this message translates to:
  /// **'صناعة'**
  String get assistEvent;

  /// No description provided for @yellowCardEvent.
  ///
  /// In ar, this message translates to:
  /// **'إنذار'**
  String get yellowCardEvent;

  /// No description provided for @redCardEvent.
  ///
  /// In ar, this message translates to:
  /// **'طرد'**
  String get redCardEvent;

  /// No description provided for @penaltyEvent.
  ///
  /// In ar, this message translates to:
  /// **'ركلة جزاء'**
  String get penaltyEvent;

  /// No description provided for @ownGoalEvent.
  ///
  /// In ar, this message translates to:
  /// **'هدف بالخطأ'**
  String get ownGoalEvent;

  /// No description provided for @injuryEvent.
  ///
  /// In ar, this message translates to:
  /// **'إصابة'**
  String get injuryEvent;

  /// No description provided for @tournamentDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل البطولة'**
  String get tournamentDetailsTitle;

  /// No description provided for @noMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مباريات'**
  String get noMatches;

  /// No description provided for @selectPlayerForSlotX.
  ///
  /// In ar, this message translates to:
  /// **'اختر لاعب الخانة {slot}'**
  String selectPlayerForSlotX(String slot);

  /// No description provided for @removePlayerFromSlot.
  ///
  /// In ar, this message translates to:
  /// **'إزالة اللاعب من هذه الخانة'**
  String get removePlayerFromSlot;

  /// No description provided for @assignedToAnotherSlot.
  ///
  /// In ar, this message translates to:
  /// **' • معيّن في خانة أخرى'**
  String get assignedToAnotherSlot;

  /// No description provided for @chooseFormation.
  ///
  /// In ar, this message translates to:
  /// **'اختر الخطة (حارس-دفاع-وسط-هجوم)'**
  String get chooseFormation;

  /// No description provided for @customFormation.
  ///
  /// In ar, this message translates to:
  /// **'خطة مخصّصة'**
  String get customFormation;

  /// No description provided for @customFormationGoalieFixed.
  ///
  /// In ar, this message translates to:
  /// **'خطة مخصّصة (الحارس ثابت)'**
  String get customFormationGoalieFixed;

  /// No description provided for @defenders.
  ///
  /// In ar, this message translates to:
  /// **'المدافعون'**
  String get defenders;

  /// No description provided for @attackers.
  ///
  /// In ar, this message translates to:
  /// **'الهجوم'**
  String get attackers;

  /// No description provided for @midfieldAndTotalX.
  ///
  /// In ar, this message translates to:
  /// **'خط الوسط: {mid}  •  المجموع: {total}'**
  String midfieldAndTotalX(String mid, String total);

  /// No description provided for @applyFormationBtn.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الخطة'**
  String get applyFormationBtn;

  /// No description provided for @assignPlayerToEverySlot.
  ///
  /// In ar, this message translates to:
  /// **'عيّن لاعباً لكل خانة في التشكيلة'**
  String get assignPlayerToEverySlot;

  /// No description provided for @failedToDetermineCaptain.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد الكابتن'**
  String get failedToDetermineCaptain;

  /// No description provided for @lineupSentForReview.
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت التشكيلة لمراجعة المنظّم'**
  String get lineupSentForReview;

  /// No description provided for @failedToSendLineup.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال التشكيلة'**
  String get failedToSendLineup;

  /// No description provided for @tournamentLineupTitle.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة البطولة'**
  String get tournamentLineupTitle;

  /// No description provided for @formationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get formationLabel;

  /// No description provided for @changeFormationBtn.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get changeFormationBtn;

  /// No description provided for @tapCircleToAssignPlayer.
  ///
  /// In ar, this message translates to:
  /// **'اضغط أي دائرة على الملعب لتعيين لاعبها'**
  String get tapCircleToAssignPlayer;

  /// No description provided for @subsCountX.
  ///
  /// In ar, this message translates to:
  /// **'الاحتياط ({count})'**
  String subsCountX(String count);

  /// No description provided for @sendingBtn.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الإرسال...'**
  String get sendingBtn;

  /// No description provided for @sendForReviewBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال للمراجعة'**
  String get sendForReviewBtn;

  /// No description provided for @lineupApproved.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلتك مقبولة'**
  String get lineupApproved;

  /// No description provided for @lineupRejectedWithNote.
  ///
  /// In ar, this message translates to:
  /// **'رُفضت تشكيلتك — {note}'**
  String lineupRejectedWithNote(String note);

  /// No description provided for @lineupRejected.
  ///
  /// In ar, this message translates to:
  /// **'رُفضت تشكيلتك'**
  String get lineupRejected;

  /// No description provided for @lineupPendingReview.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلتك قيد المراجعة'**
  String get lineupPendingReview;

  /// No description provided for @allPlayersAssignedAsStarters.
  ///
  /// In ar, this message translates to:
  /// **'كل اللاعبين معيّنون كأساسيين'**
  String get allPlayersAssignedAsStarters;

  /// No description provided for @failedToOpenPlayerProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح صفحة اللاعب'**
  String get failedToOpenPlayerProfile;

  /// No description provided for @lineupApprovedMsg.
  ///
  /// In ar, this message translates to:
  /// **'قُبلت التشكيلة'**
  String get lineupApprovedMsg;

  /// No description provided for @lineupRejectedMsg.
  ///
  /// In ar, this message translates to:
  /// **'رُفضت التشكيلة'**
  String get lineupRejectedMsg;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث الحالة'**
  String get failedToUpdateStatus;

  /// No description provided for @rejectionReasonOptional.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض (اختياري)'**
  String get rejectionReasonOptional;

  /// No description provided for @rejectionReasonExample.
  ///
  /// In ar, this message translates to:
  /// **'مثال: نقص في عدد الأساسيين'**
  String get rejectionReasonExample;

  /// No description provided for @rejectLineupBtn.
  ///
  /// In ar, this message translates to:
  /// **'رفض التشكيلة'**
  String get rejectLineupBtn;

  /// No description provided for @reviewLineupsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة التشكيلات'**
  String get reviewLineupsTitle;

  /// No description provided for @noLineupsSentYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تشكيلات مُرسَلة بعد'**
  String get noLineupsSentYet;

  /// No description provided for @lineupsWillAppearHereWhenSent.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا تشكيلات الكباتن عند إرسالها'**
  String get lineupsWillAppearHereWhenSent;

  /// No description provided for @approvedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مقبولة'**
  String get approvedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة'**
  String get rejectedStatus;

  /// No description provided for @pendingReviewStatus.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get pendingReviewStatus;

  /// No description provided for @formationX.
  ///
  /// In ar, this message translates to:
  /// **'الخطة: {formation}'**
  String formationX(String formation);

  /// No description provided for @subsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاحتياط:'**
  String get subsLabel;

  /// No description provided for @yourNoteX.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظتك: {note}'**
  String yourNoteX(String note);

  /// No description provided for @acceptBtn.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get acceptBtn;

  /// No description provided for @rejectBtn.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get rejectBtn;

  /// No description provided for @changeDecisionBtn.
  ///
  /// In ar, this message translates to:
  /// **'تغيير القرار'**
  String get changeDecisionBtn;

  /// No description provided for @failedToUploadBannerImage.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر رفع صورة البانر'**
  String get failedToUploadBannerImage;

  /// No description provided for @failedToUploadSponsorLogo.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر رفع لوغو الداعم'**
  String get failedToUploadSponsorLogo;

  /// No description provided for @sponsorNameTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم الداعم'**
  String get sponsorNameTitle;

  /// No description provided for @sponsorNameExample.
  ///
  /// In ar, this message translates to:
  /// **'مثال: شركة الراعي'**
  String get sponsorNameExample;

  /// No description provided for @addBtn.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get addBtn;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التعديلات'**
  String get failedToSaveChanges;

  /// No description provided for @editRulesAndSponsorsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الشروط والداعمين'**
  String get editRulesAndSponsorsTitle;

  /// No description provided for @rulesAndTermsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والقوانين'**
  String get rulesAndTermsLabel;

  /// No description provided for @writeRulesAndTermsHere.
  ///
  /// In ar, this message translates to:
  /// **'اكتب شروط وقوانين البطولة هنا…'**
  String get writeRulesAndTermsHere;

  /// No description provided for @adBannersSection.
  ///
  /// In ar, this message translates to:
  /// **'بانر الإعلانات'**
  String get adBannersSection;

  /// No description provided for @sponsorsSection.
  ///
  /// In ar, this message translates to:
  /// **'الداعمون'**
  String get sponsorsSection;

  /// No description provided for @imageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get imageLabel;

  /// No description provided for @sponsorLabel.
  ///
  /// In ar, this message translates to:
  /// **'داعم'**
  String get sponsorLabel;

  /// No description provided for @standingsTableTitle.
  ///
  /// In ar, this message translates to:
  /// **'جدول الترتيب'**
  String get standingsTableTitle;

  /// No description provided for @knockoutStageLabel.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة الإقصائية'**
  String get knockoutStageLabel;

  /// No description provided for @bracketNotGeneratedYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تُولَّد الشجرة بعد'**
  String get bracketNotGeneratedYet;

  /// No description provided for @reportSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال البلاغ — سيراجعه الفريق قريباً'**
  String get reportSentSuccess;

  /// No description provided for @reportSentFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال البلاغ — حاول مرة أخرى'**
  String get reportSentFailed;

  /// No description provided for @submitReportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقديم بلاغ'**
  String get submitReportTitle;

  /// No description provided for @reportAboutTarget.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ عن {label}'**
  String reportAboutTarget(String label);

  /// No description provided for @reportReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب البلاغ'**
  String get reportReasonLabel;

  /// No description provided for @problemDescriptionOptional.
  ///
  /// In ar, this message translates to:
  /// **'وصف المشكلة (اختياري)'**
  String get problemDescriptionOptional;

  /// No description provided for @explainProblemInDetailHint.
  ///
  /// In ar, this message translates to:
  /// **'اشرح المشكلة بتفاصيل أكثر...'**
  String get explainProblemInDetailHint;

  /// No description provided for @falseReportsWarning.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: البلاغات الكاذبة أو التافهة قد تؤدي إلى تقييد حسابك.'**
  String get falseReportsWarning;

  /// No description provided for @submitReportBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get submitReportBtn;

  /// No description provided for @offensiveContentLabel.
  ///
  /// In ar, this message translates to:
  /// **'محتوى مسيء'**
  String get offensiveContentLabel;

  /// No description provided for @inappropriateBehaviorLabel.
  ///
  /// In ar, this message translates to:
  /// **'سلوك غير لائق'**
  String get inappropriateBehaviorLabel;

  /// No description provided for @misleadingInfoLabel.
  ///
  /// In ar, this message translates to:
  /// **'معلومات مضلّلة'**
  String get misleadingInfoLabel;

  /// No description provided for @otherReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get otherReasonLabel;

  /// No description provided for @playerLabel.
  ///
  /// In ar, this message translates to:
  /// **'لاعب'**
  String get playerLabel;

  /// No description provided for @teamLabel.
  ///
  /// In ar, this message translates to:
  /// **'فريق'**
  String get teamLabel;

  /// No description provided for @userLabel.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get userLabel;

  /// No description provided for @lastUpdatedDate.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: {date}'**
  String lastUpdatedDate(String date);

  /// No description provided for @toubaPlatform.
  ///
  /// In ar, this message translates to:
  /// **'منصة طوبة ⚽'**
  String get toubaPlatform;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In ar, this message translates to:
  /// **'تحترم منصة «طوبة» خصوصيتك. توضّح هذه السياسة أنواع البيانات التي نجمعها، وكيف نستخدمها ونحميها عند استخدامك للتطبيق. باستخدامك «طوبة» فإنك توافق على ما ورد في هذه السياسة.'**
  String get privacyPolicyIntro;

  /// No description provided for @ppSec1Title.
  ///
  /// In ar, this message translates to:
  /// **'1. البيانات التي نجمعها'**
  String get ppSec1Title;

  /// No description provided for @ppSec1Body.
  ///
  /// In ar, this message translates to:
  /// **'عند إنشاء حساب نجمع: الاسم، البريد الإلكتروني، رقم الهاتف، وصورة الملف الشخصي (اختيارية). عند ارتباطك بسجل لاعب أو فريق قد تُحفظ بياناتك الكروية (المركز، الرقم، الفريق) وإحصائياتك (الأهداف، الصناعة، البطاقات) التي يُنشئها النظام من نتائج المباريات. كما نجمع تلقائياً بيانات استخدام وتحليلات وتقارير أعطال عبر خدمات Google Firebase لتحسين أداء التطبيق.'**
  String get ppSec1Body;

  /// No description provided for @ppSec2Title.
  ///
  /// In ar, this message translates to:
  /// **'2. كيف نستخدم بياناتك'**
  String get ppSec2Title;

  /// No description provided for @ppSec2Body.
  ///
  /// In ar, this message translates to:
  /// **'نستخدم بياناتك لتشغيل حسابك، وإدارة الفرق والبطولات والمباريات، وعرض بطاقتك وإحصائياتك، والتواصل معك عند الحاجة، وإرسال إشعارات متعلقة بنشاطك (مثل قبول طلب انضمام أو نتيجة مباراة)، وتحسين الخدمة وحمايتها من إساءة الاستخدام.'**
  String get ppSec2Body;

  /// No description provided for @ppSec3Title.
  ///
  /// In ar, this message translates to:
  /// **'3. مشاركة البيانات'**
  String get ppSec3Title;

  /// No description provided for @ppSec3Body.
  ///
  /// In ar, this message translates to:
  /// **'لا نبيع بياناتك الشخصية لأي طرف. تُعالَج بعض البيانات لدى مزوّدي الخدمة (Google Firebase للاستضافة والمصادقة والتحليلات). تظهر بعض المعلومات علناً داخل التطبيق بطبيعتها (اسم الفريق، اسم اللاعب، الإحصائيات، الترتيب). لا يُعرض رقم هاتف مسؤول الفريق علناً.'**
  String get ppSec3Body;

  /// No description provided for @ppSec4Title.
  ///
  /// In ar, this message translates to:
  /// **'4. حقوقك والتحكم ببياناتك'**
  String get ppSec4Title;

  /// No description provided for @ppSec4Body.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تعديل بيانات ملفك الشخصي في أي وقت من شاشة «تعديل الملف». كما يمكنك حذف حسابك نهائياً من إعدادات الحساب؛ عند الحذف تُزال بياناتك الشخصية المرتبطة بالحساب وفق ما يسمح به القانون.'**
  String get ppSec4Body;

  /// No description provided for @ppSec5Title.
  ///
  /// In ar, this message translates to:
  /// **'5. أمن البيانات والاحتفاظ بها'**
  String get ppSec5Title;

  /// No description provided for @ppSec5Body.
  ///
  /// In ar, this message translates to:
  /// **'نتّخذ إجراءات تقنية لحماية بياناتك (قواعد أمان على الخادم، التحقق من سلامة الطلبات عبر App Check). نحتفظ ببياناتك طالما حسابك فعّال أو بالقدر اللازم لتقديم الخدمة والالتزام بالأنظمة.'**
  String get ppSec5Body;

  /// No description provided for @ppSec6Title.
  ///
  /// In ar, this message translates to:
  /// **'6. الأطفال'**
  String get ppSec6Title;

  /// No description provided for @ppSec6Body.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق غير موجّه للأطفال دون 13 عاماً، ولا نجمع بياناتهم عن قصد. إن تبيّن خلاف ذلك، نحذف البيانات فور علمنا.'**
  String get ppSec6Body;

  /// No description provided for @ppSec7Title.
  ///
  /// In ar, this message translates to:
  /// **'7. تغييرات على هذه السياسة'**
  String get ppSec7Title;

  /// No description provided for @ppSec7Body.
  ///
  /// In ar, this message translates to:
  /// **'قد نحدّث هذه السياسة من حين لآخر، وسننشر النسخة المحدّثة داخل التطبيق مع تحديث تاريخ «آخر تحديث» أعلاه.'**
  String get ppSec7Body;

  /// No description provided for @ppSec8Title.
  ///
  /// In ar, this message translates to:
  /// **'8. التواصل'**
  String get ppSec8Title;

  /// No description provided for @ppSec8Body.
  ///
  /// In ar, this message translates to:
  /// **'لأي استفسار حول الخصوصية، تواصل معنا عبر: senanxsh@gmail.com'**
  String get ppSec8Body;

  /// No description provided for @termsConditionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsConditionsTitle;

  /// No description provided for @termsIntro.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في «طوبة». باستخدامك للتطبيق فإنك توافق على هذه الشروط والأحكام. يُرجى قراءتها بعناية.'**
  String get termsIntro;

  /// No description provided for @tcSec1Title.
  ///
  /// In ar, this message translates to:
  /// **'1. طبيعة الخدمة'**
  String get tcSec1Title;

  /// No description provided for @tcSec1Body.
  ///
  /// In ar, this message translates to:
  /// **'«طوبة» منصة لتنظيم كرة القدم الشعبية والهواة: إنشاء الفرق، إدارة اللاعبين، تنظيم البطولات والمباريات، وعرض الترتيب والإحصائيات.'**
  String get tcSec1Body;

  /// No description provided for @tcSec2Title.
  ///
  /// In ar, this message translates to:
  /// **'2. الحساب ومسؤوليتك'**
  String get tcSec2Title;

  /// No description provided for @tcSec2Body.
  ///
  /// In ar, this message translates to:
  /// **'أنت مسؤول عن دقة بياناتك وعن الحفاظ على سرّية حسابك وكل ما يجري تحته. يجب أن تكون البيانات التي تدخلها صحيحة وغير منتحلة لهوية الغير.'**
  String get tcSec2Body;

  /// No description provided for @tcSec3Title.
  ///
  /// In ar, this message translates to:
  /// **'3. الأدوار والصلاحيات'**
  String get tcSec3Title;

  /// No description provided for @tcSec3Body.
  ///
  /// In ar, this message translates to:
  /// **'يدير الكابتن فريقه ولاعبيه. تُمنح صلاحيات تنظيم البطولات وتأكيد النتائج من إدارة المنصة. تأكيد نتيجة المباراة من اختصاص المنظّم حصراً، والإحصائيات يحسبها النظام تلقائياً ولا يجوز التلاعب بها.'**
  String get tcSec3Body;

  /// No description provided for @tcSec4Title.
  ///
  /// In ar, this message translates to:
  /// **'4. الاستخدام المقبول'**
  String get tcSec4Title;

  /// No description provided for @tcSec4Body.
  ///
  /// In ar, this message translates to:
  /// **'يُمنع استخدام التطبيق في أي نشاط مخالف للقانون، أو نشر محتوى مسيء أو صور غير لائقة، أو انتحال صفة الغير، أو محاولة العبث ببيانات الفرق والبطولات والإحصائيات. نحتفظ بحق إزالة المحتوى المخالف وإيقاف الحسابات المخالفة.'**
  String get tcSec4Body;

  /// No description provided for @tcSec5Title.
  ///
  /// In ar, this message translates to:
  /// **'5. المحتوى الذي ترفعه'**
  String get tcSec5Title;

  /// No description provided for @tcSec5Body.
  ///
  /// In ar, this message translates to:
  /// **'تبقى ملكية المحتوى الذي ترفعه (كالصور) لك، وتمنح المنصة ترخيصاً لعرضه داخل التطبيق لأغراض تشغيل الخدمة. أنت مسؤول عن امتلاكك حقوق ما ترفعه.'**
  String get tcSec5Body;

  /// No description provided for @tcSec6Title.
  ///
  /// In ar, this message translates to:
  /// **'6. البلاغات'**
  String get tcSec6Title;

  /// No description provided for @tcSec6Body.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك الإبلاغ عن أي محتوى أو سلوك مخالف عبر أدوات الإبلاغ في التطبيق، وستراجعه الإدارة وتتخذ الإجراء المناسب.'**
  String get tcSec6Body;

  /// No description provided for @tcSec7Title.
  ///
  /// In ar, this message translates to:
  /// **'7. إخلاء المسؤولية'**
  String get tcSec7Title;

  /// No description provided for @tcSec7Body.
  ///
  /// In ar, this message translates to:
  /// **'تُقدَّم الخدمة «كما هي». نبذل جهداً لضمان دقة البيانات لكننا لا نضمن خلوها من الأخطاء، ولا نتحمّل مسؤولية أي نزاعات تنشأ بين الفرق أو اللاعبين خارج المنصة.'**
  String get tcSec7Body;

  /// No description provided for @tcSec8Title.
  ///
  /// In ar, this message translates to:
  /// **'8. إنهاء الخدمة'**
  String get tcSec8Title;

  /// No description provided for @tcSec8Body.
  ///
  /// In ar, this message translates to:
  /// **'يحق لك حذف حسابك في أي وقت. ويحق للإدارة إيقاف أو إنهاء الحسابات المخالفة لهذه الشروط.'**
  String get tcSec8Body;

  /// No description provided for @tcSec9Title.
  ///
  /// In ar, this message translates to:
  /// **'9. القانون المطبّق والتواصل'**
  String get tcSec9Title;

  /// No description provided for @tcSec9Body.
  ///
  /// In ar, this message translates to:
  /// **'تخضع هذه الشروط لأنظمة جمهورية العراق. لأي استفسار: senanxsh@gmail.com'**
  String get tcSec9Body;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم الإدارة'**
  String get adminDashboardTitle;

  /// No description provided for @manageLocationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المواقع'**
  String get manageLocationsTitle;

  /// No description provided for @manageLocationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'المحافظات والمناطق المسموح باللعب فيها'**
  String get manageLocationsSubtitle;

  /// No description provided for @manageRolesTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الصلاحيات'**
  String get manageRolesTitle;

  /// No description provided for @manageRolesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'منح ألقاب المنظمين والحكام'**
  String get manageRolesSubtitle;

  /// No description provided for @adminReportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'البلاغات'**
  String get adminReportsTitle;

  /// No description provided for @adminReportsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة البلاغات الواردة عن لاعبين وفرق'**
  String get adminReportsSubtitle;

  /// No description provided for @adminTournamentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة البطولات'**
  String get adminTournamentsTitle;

  /// No description provided for @adminTournamentsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الأسماء والصور والكؤوس والجوائز'**
  String get adminTournamentsSubtitle;

  /// No description provided for @adminBannersTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الإعلانات'**
  String get adminBannersTitle;

  /// No description provided for @adminBannersSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بانرات سلايدر الصفحة الرئيسية'**
  String get adminBannersSubtitle;

  /// No description provided for @adminNewsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الأخبار'**
  String get adminNewsTitle;

  /// No description provided for @adminNewsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نشر وتعديل أخبار الصفحة الرئيسية'**
  String get adminNewsSubtitle;

  /// No description provided for @adminRefereeApplicationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات التحكيم'**
  String get adminRefereeApplicationsTitle;

  /// No description provided for @adminRefereeApplicationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'موافقة/رفض طلبات الراغبين بالتحكيم'**
  String get adminRefereeApplicationsSubtitle;

  /// No description provided for @adminDisputesTitle.
  ///
  /// In ar, this message translates to:
  /// **'نزاعات فكّ الارتباط'**
  String get adminDisputesTitle;

  /// No description provided for @adminDisputesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات خروج رفضها الكباتن وصعّدها اللاعبون'**
  String get adminDisputesSubtitle;

  /// No description provided for @adminChallengesTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة التحديات'**
  String get adminChallengesTitle;

  /// No description provided for @adminChallengesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء طلبات التحدّي المتروكة (بلا متقدّمين منذ أيام)'**
  String get adminChallengesSubtitle;

  /// No description provided for @adminSectionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الأقسام'**
  String get adminSectionsTitle;

  /// No description provided for @adminSectionsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إظهار/إخفاء أقسام التطبيق (مثل البطولات)'**
  String get adminSectionsSubtitle;

  /// No description provided for @adminSubscriptionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكواد التفعيل'**
  String get adminSubscriptionsTitle;

  /// No description provided for @adminSubscriptionsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'توليد أكواد الاشتراك + مدة التجربة + واتساب التفعيل'**
  String get adminSubscriptionsSubtitle;

  /// No description provided for @adminVerifyTeamsTitle.
  ///
  /// In ar, this message translates to:
  /// **'توثيق الفرق'**
  String get adminVerifyTeamsTitle;

  /// No description provided for @activateWithCode.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل بكود'**
  String get activateWithCode;

  /// No description provided for @enterActivationCodePrompt.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود التفعيل الذي حصلت عليه من الإدارة:'**
  String get enterActivationCodePrompt;

  /// No description provided for @activationCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'TBA-XXXX-XXXX'**
  String get activationCodeHint;

  /// No description provided for @cancelBtn.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelBtn;

  /// No description provided for @activateBtn.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activateBtn;

  /// No description provided for @subscriptionActivatedXMonths.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل اشتراكك 🎉{months}'**
  String subscriptionActivatedXMonths(String months);

  /// No description provided for @failedToActivate.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التفعيل'**
  String get failedToActivate;

  /// No description provided for @whatsappActivationMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، أريد تفعيل اشتراك طوبة'**
  String get whatsappActivationMessage;

  /// No description provided for @failedToOpenWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح واتساب'**
  String get failedToOpenWhatsapp;

  /// No description provided for @mySubscriptionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكي'**
  String get mySubscriptionTitle;

  /// No description provided for @contactToGetCode.
  ///
  /// In ar, this message translates to:
  /// **'تواصل للحصول على كود'**
  String get contactToGetCode;

  /// No description provided for @notSubscribed.
  ///
  /// In ar, this message translates to:
  /// **'غير مشترك'**
  String get notSubscribed;

  /// No description provided for @subscriptionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الاشتراك'**
  String get subscriptionExpired;

  /// No description provided for @freeTrial.
  ///
  /// In ar, this message translates to:
  /// **'تجربة مجانية'**
  String get freeTrial;

  /// No description provided for @expiresAtDate.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي: {date}'**
  String expiresAtDate(String date);

  /// No description provided for @daysRemaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقّي {days} يوم'**
  String daysRemaining(String days);

  /// No description provided for @expiresToday.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي اليوم'**
  String get expiresToday;

  /// No description provided for @whatDoesSubscriptionUnlock.
  ///
  /// In ar, this message translates to:
  /// **'ماذا يفتح الاشتراك؟'**
  String get whatDoesSubscriptionUnlock;

  /// No description provided for @benefitChallengeRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلب تحدّيات الفرق والموافقة عليها'**
  String get benefitChallengeRequests;

  /// No description provided for @benefitOpenChatWithOpponent.
  ///
  /// In ar, this message translates to:
  /// **'فتح محادثة مع كابتن الفريق المنافس'**
  String get benefitOpenChatWithOpponent;

  /// No description provided for @benefitParticipateInTournaments.
  ///
  /// In ar, this message translates to:
  /// **'المشاركة في البطولات (حسب نوع البطولة)'**
  String get benefitParticipateInTournaments;

  /// No description provided for @featureRequiresSubscription.
  ///
  /// In ar, this message translates to:
  /// **'{feature} يتطلّب اشتراكاً'**
  String featureRequiresSubscription(String feature);

  /// No description provided for @activateSubscriptionToUnlockFeatures.
  ///
  /// In ar, this message translates to:
  /// **'فعّل اشتراكك لفتح التحدّيات والمحادثة. التفعيل بكود من الإدارة.'**
  String get activateSubscriptionToUnlockFeatures;

  /// No description provided for @manageSubscriptionActivateCodeBtn.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك / تفعيل بكود'**
  String get manageSubscriptionActivateCodeBtn;

  /// No description provided for @laterBtn.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get laterBtn;

  /// No description provided for @myChatsTitle.
  ///
  /// In ar, this message translates to:
  /// **'محادثاتي'**
  String get myChatsTitle;

  /// No description provided for @noChatsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات بعد'**
  String get noChatsYet;

  /// No description provided for @chatOpensWhenChallengeAccepted.
  ///
  /// In ar, this message translates to:
  /// **'تُفتح المحادثة عند قبول تحدٍّ بين فريقين'**
  String get chatOpensWhenChallengeAccepted;

  /// No description provided for @loginToViewYourChats.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض محادثاتك'**
  String get loginToViewYourChats;

  /// No description provided for @chatsOpenBetweenCaptainsWhenChallengeAccepted.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات تُفتح بين كباتن الفرق عند قبول تحدٍّ'**
  String get chatsOpenBetweenCaptainsWhenChallengeAccepted;

  /// No description provided for @loginOrCreateAccountBtn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول / إنشاء حساب'**
  String get loginOrCreateAccountBtn;

  /// No description provided for @startConversation.
  ///
  /// In ar, this message translates to:
  /// **'بدء المحادثة'**
  String get startConversation;

  /// No description provided for @typeMessageHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get typeMessageHint;

  /// No description provided for @requestChallengeWithTeam.
  ///
  /// In ar, this message translates to:
  /// **'نطلب تحدّي فريق {team}'**
  String requestChallengeWithTeam(String team);

  /// No description provided for @loginFirstToProceed.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أولاً'**
  String get loginFirstToProceed;

  /// No description provided for @youDoNotHaveATeamToRequestChallenge.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك فريقاً لإرسال تحدٍّ باسمه'**
  String get youDoNotHaveATeamToRequestChallenge;

  /// No description provided for @failedToLoadYourTeamData.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل بيانات فريقك'**
  String get failedToLoadYourTeamData;

  /// No description provided for @youAlreadyHaveOpenRequestEditIt.
  ///
  /// In ar, this message translates to:
  /// **'لديك طلب مفتوح بالفعل — عدّله من «تحدّيات الفرق»'**
  String get youAlreadyHaveOpenRequestEditIt;

  /// No description provided for @failedToPublishRequest.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر نشر الطلب'**
  String get failedToPublishRequest;

  /// No description provided for @requestChallengeTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب تحدٍّ'**
  String get requestChallengeTitle;

  /// No description provided for @directedChallengeToTeam.
  ///
  /// In ar, this message translates to:
  /// **'تحدٍّ موجّه إلى «{team}»'**
  String directedChallengeToTeam(String team);

  /// No description provided for @noteSuggestedPlaceTime.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة — المكان/التوقيت المقترح'**
  String get noteSuggestedPlaceTime;

  /// No description provided for @publishChallengeRequestBtn.
  ///
  /// In ar, this message translates to:
  /// **'نشر طلب التحدّي'**
  String get publishChallengeRequestBtn;

  /// No description provided for @teamChallengesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحدّيات الفرق'**
  String get teamChallengesTitle;

  /// No description provided for @teamRequestsTab.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الفرق'**
  String get teamRequestsTab;

  /// No description provided for @myChallengesTab.
  ///
  /// In ar, this message translates to:
  /// **'تحدياتي'**
  String get myChallengesTab;

  /// No description provided for @requestChallengeBtn.
  ///
  /// In ar, this message translates to:
  /// **'اطلب تحدي'**
  String get requestChallengeBtn;

  /// No description provided for @noOpenChallengeRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات تحدٍّ مفتوحة حالياً'**
  String get noOpenChallengeRequests;

  /// No description provided for @tapToViewTeamPage.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لعرض صفحة الفريق'**
  String get tapToViewTeamPage;

  /// No description provided for @appliedStatus.
  ///
  /// In ar, this message translates to:
  /// **'تم التقديم'**
  String get appliedStatus;

  /// No description provided for @acceptChallengeBtn.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على التحدي'**
  String get acceptChallengeBtn;

  /// No description provided for @pleaseLoginToView.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول'**
  String get pleaseLoginToView;

  /// No description provided for @myRequestsLabel.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myRequestsLabel;

  /// No description provided for @noChallengeRequestsSentYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تُرسل أي طلب تحدٍّ بعد'**
  String get noChallengeRequestsSentYet;

  /// No description provided for @appliedToLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقدّمت إليها'**
  String get appliedToLabel;

  /// No description provided for @noChallengeRequestsAppliedYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تتقدّم لأي تحدٍّ بعد'**
  String get noChallengeRequestsAppliedYet;

  /// No description provided for @challengeRequestLabel.
  ///
  /// In ar, this message translates to:
  /// **'طلب تحدٍّ'**
  String get challengeRequestLabel;

  /// No description provided for @opponentLabelX.
  ///
  /// In ar, this message translates to:
  /// **'الخصم: {name}'**
  String opponentLabelX(String name);

  /// No description provided for @opponentLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get opponentLabel;

  /// No description provided for @openChatBtn.
  ///
  /// In ar, this message translates to:
  /// **'فتح المحادثة'**
  String get openChatBtn;

  /// No description provided for @applicantsLabelX.
  ///
  /// In ar, this message translates to:
  /// **'المتقدّمون ({count})'**
  String applicantsLabelX(int count);

  /// No description provided for @waitingForTeamsToApply.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار تقديم الفرق…'**
  String get waitingForTeamsToApply;

  /// No description provided for @tapToViewTeamBeforeAccepting.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لعرض الفريق قبل القبول'**
  String get tapToViewTeamBeforeAccepting;

  /// No description provided for @cancelRequestBtn.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelRequestBtn;

  /// No description provided for @requestCancelledStatus.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي الطلب'**
  String get requestCancelledStatus;

  /// No description provided for @waitingForRequesterSelection.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار اختيار صاحب الطلب'**
  String get waitingForRequesterSelection;

  /// No description provided for @yourTeamSelected.
  ///
  /// In ar, this message translates to:
  /// **'تم اختيار فريقك! 🎉'**
  String get yourTeamSelected;

  /// No description provided for @anotherTeamSelected.
  ///
  /// In ar, this message translates to:
  /// **'اختار فريقاً آخر'**
  String get anotherTeamSelected;

  /// No description provided for @chatLabel.
  ///
  /// In ar, this message translates to:
  /// **'محادثة'**
  String get chatLabel;

  /// No description provided for @agreeToChallengeSub.
  ///
  /// In ar, this message translates to:
  /// **'الموافقة على التحدّي'**
  String get agreeToChallengeSub;

  /// No description provided for @teamAppliedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تقديم فريقك للتحدّي'**
  String get teamAppliedSuccessfully;

  /// No description provided for @failedToApply.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التقديم'**
  String get failedToApply;

  /// No description provided for @acceptChallengeSub.
  ///
  /// In ar, this message translates to:
  /// **'قبول التحدّي'**
  String get acceptChallengeSub;

  /// No description provided for @challengeAcceptedBetweenTeams.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول التحدّي بين «{team1}» و«{team2}» 👋 اتفقوا على الموعد والمكان.'**
  String challengeAcceptedBetweenTeams(String team1, String team2);

  /// No description provided for @failedToAcceptChallenge.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر قبول التحدّي'**
  String get failedToAcceptChallenge;

  /// No description provided for @failedToCancel.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الإلغاء'**
  String get failedToCancel;

  /// No description provided for @requestChallengeSub.
  ///
  /// In ar, this message translates to:
  /// **'طلب تحدٍّ'**
  String get requestChallengeSub;

  /// No description provided for @friendlyChallengeRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب تحدٍّ ودّي'**
  String get friendlyChallengeRequestTitle;

  /// No description provided for @editRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الطلب'**
  String get editRequestTitle;

  /// No description provided for @onBehalfOfTeam.
  ///
  /// In ar, this message translates to:
  /// **'باسم فريق «{team}» • {city}'**
  String onBehalfOfTeam(String team, String city);

  /// No description provided for @noteOptionalHint.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري) — المكان/التوقيت المقترح'**
  String get noteOptionalHint;

  /// No description provided for @suggestedDateOptional.
  ///
  /// In ar, this message translates to:
  /// **'موعد مقترح (اختياري)'**
  String get suggestedDateOptional;

  /// No description provided for @publishRequestBtn.
  ///
  /// In ar, this message translates to:
  /// **'نشر الطلب'**
  String get publishRequestBtn;

  /// No description provided for @saveEditBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديل'**
  String get saveEditBtn;

  /// No description provided for @requestUpdatedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الطلب'**
  String get requestUpdatedSuccessfully;

  /// No description provided for @challengeRequestPublished.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر طلب التحدّي'**
  String get challengeRequestPublished;

  /// No description provided for @failedToSaveRequest.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الطلب'**
  String get failedToSaveRequest;

  /// No description provided for @youHaveAnOpenRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'لديك طلب مفتوح'**
  String get youHaveAnOpenRequestTitle;

  /// No description provided for @cannotPublishMultipleRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن نشر أكثر من طلب تحدٍّ مفتوح في آنٍ واحد. عدّل طلبك الحالي أو ألغِه أولاً.'**
  String get cannotPublishMultipleRequests;

  /// No description provided for @acceptedStatus.
  ///
  /// In ar, this message translates to:
  /// **'تم القبول'**
  String get acceptedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get cancelledStatus;

  /// No description provided for @openStatus.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get openStatus;

  /// No description provided for @rulesAndTermsTab.
  ///
  /// In ar, this message translates to:
  /// **'شروط وقوانين'**
  String get rulesAndTermsTab;

  /// No description provided for @participatingTeamsTab.
  ///
  /// In ar, this message translates to:
  /// **'الفرق المشاركة'**
  String get participatingTeamsTab;

  /// No description provided for @cityAndType.
  ///
  /// In ar, this message translates to:
  /// **'{city} • {type}'**
  String cityAndType(String city, String type);

  /// No description provided for @paidTournamentWithInfo.
  ///
  /// In ar, this message translates to:
  /// **'بطولة باشتراك • {info}'**
  String paidTournamentWithInfo(String info);

  /// No description provided for @paidTournament.
  ///
  /// In ar, this message translates to:
  /// **'باشتراك — يُضاف الفريق بعد الدفع'**
  String get paidTournament;

  /// No description provided for @reviewTeamLineups.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة تشكيلات الفرق'**
  String get reviewTeamLineups;

  /// No description provided for @myTournamentLineup.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلتي في البطولة'**
  String get myTournamentLineup;

  /// No description provided for @applyAsRefereeForTournament.
  ///
  /// In ar, this message translates to:
  /// **'تقديم طلب تحكيم لهذه البطولة'**
  String get applyAsRefereeForTournament;

  /// No description provided for @matchesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المباريات'**
  String get matchesTitle;

  /// No description provided for @exportPdfBtn.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get exportPdfBtn;

  /// No description provided for @termsAndRulesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والقوانين'**
  String get termsAndRulesTitle;

  /// No description provided for @sponsorsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الداعمون'**
  String get sponsorsTitle;

  /// No description provided for @editRulesAndSponsors.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الشروط والداعمين'**
  String get editRulesAndSponsors;

  /// No description provided for @noRulesOrSponsorsEditToAdd.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شروط أو داعمون بعد — اضغط «تعديل» للإضافة'**
  String get noRulesOrSponsorsEditToAdd;

  /// No description provided for @noRulesOrSponsors.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شروط أو داعمون لهذه البطولة'**
  String get noRulesOrSponsors;

  /// No description provided for @teamLineupsStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة تشكيلات الفرق ({count})'**
  String teamLineupsStatus(String count);

  /// No description provided for @tapToReviewOrRemind.
  ///
  /// In ar, this message translates to:
  /// **'اضغط فريقاً أرسل لمراجعة تشكيلته، أو فريقاً لم يُرسل لتذكيره.'**
  String get tapToReviewOrRemind;

  /// No description provided for @tapToViewLineup.
  ///
  /// In ar, this message translates to:
  /// **'اضغط فريقاً أرسل لعرض تشكيلته.'**
  String get tapToViewLineup;

  /// No description provided for @noParticipatingTeams.
  ///
  /// In ar, this message translates to:
  /// **'لا فرق مشاركة'**
  String get noParticipatingTeams;

  /// No description provided for @notSent.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرسل'**
  String get notSent;

  /// No description provided for @verified.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق'**
  String get verified;

  /// No description provided for @rejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة'**
  String get rejected;

  /// No description provided for @sent.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال'**
  String get sent;

  /// No description provided for @captainNotSentLineup.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرسِل الكابتن تشكيلته بعد'**
  String get captainNotSentLineup;

  /// No description provided for @remindTeamX.
  ///
  /// In ar, this message translates to:
  /// **'تذكير فريق {name}'**
  String remindTeamX(String name);

  /// No description provided for @remindCaptainMessageBody.
  ///
  /// In ar, this message translates to:
  /// **'سيصل تنبيه لكابتن الفريق بضرورة إرسال التشكيلة. إن لم تُرسَل يمكنك إقصاء الفريق أو إدخال خسارة 3-0 يدوياً.'**
  String get remindCaptainMessageBody;

  /// No description provided for @customMessageOptional.
  ///
  /// In ar, this message translates to:
  /// **'رسالة مخصّصة (اختياري)'**
  String get customMessageOptional;

  /// No description provided for @sendReminderBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التذكير'**
  String get sendReminderBtn;

  /// No description provided for @reminderSentToCaptainX.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل التذكير لكابتن {name}'**
  String reminderSentToCaptainX(String name);

  /// No description provided for @failedToSendReminder.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال التذكير'**
  String get failedToSendReminder;

  /// No description provided for @tournamentChampion.
  ///
  /// In ar, this message translates to:
  /// **'بطل البطولة'**
  String get tournamentChampion;

  /// No description provided for @prizesX.
  ///
  /// In ar, this message translates to:
  /// **'الجوائز: {prizes}'**
  String prizesX(String prizes);

  /// No description provided for @sponsorX.
  ///
  /// In ar, this message translates to:
  /// **'الراعي: {name}'**
  String sponsorX(String name);

  /// No description provided for @knockoutType.
  ///
  /// In ar, this message translates to:
  /// **'خروج المغلوب'**
  String get knockoutType;

  /// No description provided for @groupsType.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات'**
  String get groupsType;

  /// No description provided for @leagueType.
  ///
  /// In ar, this message translates to:
  /// **'دوري'**
  String get leagueType;

  /// No description provided for @knockoutStage.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة الإقصائية'**
  String get knockoutStage;

  /// No description provided for @generateKnockoutStageBtn.
  ///
  /// In ar, this message translates to:
  /// **'توليد المرحلة الإقصائية'**
  String get generateKnockoutStageBtn;

  /// No description provided for @generatingStage.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ توليد المرحلة...'**
  String get generatingStage;

  /// No description provided for @knockoutStageGenerated.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد المرحلة الإقصائية'**
  String get knockoutStageGenerated;

  /// No description provided for @failedToGenerateStage.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التوليد — تأكّد من اكتمال مباريات المجموعات'**
  String get failedToGenerateStage;

  /// No description provided for @unscheduledTime.
  ///
  /// In ar, this message translates to:
  /// **'موعد غير محدد'**
  String get unscheduledTime;

  /// No description provided for @withoutSchedule.
  ///
  /// In ar, this message translates to:
  /// **'بدون موعد'**
  String get withoutSchedule;

  /// No description provided for @vs.
  ///
  /// In ar, this message translates to:
  /// **'ضد'**
  String get vs;

  /// No description provided for @assignRefereeBtn.
  ///
  /// In ar, this message translates to:
  /// **'تعيين حكم'**
  String get assignRefereeBtn;

  /// No description provided for @changeRefereeBtn.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الحكم'**
  String get changeRefereeBtn;

  /// No description provided for @myTeamFormationX.
  ///
  /// In ar, this message translates to:
  /// **'خطة فريقي: {f}'**
  String myTeamFormationX(String f);

  /// No description provided for @setMyTeamFormationBtn.
  ///
  /// In ar, this message translates to:
  /// **'تحديد خطة فريقي'**
  String get setMyTeamFormationBtn;

  /// No description provided for @startMatchBtn.
  ///
  /// In ar, this message translates to:
  /// **'بدأ المباراة'**
  String get startMatchBtn;

  /// No description provided for @editScheduleBtn.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الموعد'**
  String get editScheduleBtn;

  /// No description provided for @setScheduleBtn.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الموعد'**
  String get setScheduleBtn;

  /// No description provided for @enterResultBtn.
  ///
  /// In ar, this message translates to:
  /// **'إدخال النتيجة'**
  String get enterResultBtn;

  /// No description provided for @refereeRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب تحكيم'**
  String get refereeRequest;

  /// No description provided for @applyAsRefereeDialogBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تقديم طلب للتحكيم في بطولة «{name}»؟ سيراجعه الأدمن.'**
  String applyAsRefereeDialogBody(String name);

  /// No description provided for @submitBtn.
  ///
  /// In ar, this message translates to:
  /// **'تقديم'**
  String get submitBtn;

  /// No description provided for @refereeRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب التحكيم للأدمن'**
  String get refereeRequestSent;

  /// No description provided for @chooseTeamFormationForMatch.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطة فريقك لهذه المباراة'**
  String get chooseTeamFormationForMatch;

  /// No description provided for @preparingReport.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تجهيز التقرير...'**
  String get preparingReport;

  /// No description provided for @failedToExportReport.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تصدير التقرير'**
  String get failedToExportReport;

  /// No description provided for @failedToFetchReferees.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب الحكّام'**
  String get failedToFetchReferees;

  /// No description provided for @chooseRefereeForMatch.
  ///
  /// In ar, this message translates to:
  /// **'اختر حكماً للمباراة'**
  String get chooseRefereeForMatch;

  /// No description provided for @noRefereesAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حكّام متاحون — يمنحهم الأدمن الصلاحية'**
  String get noRefereesAvailable;

  /// No description provided for @unassignRefereeBtn.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء تعيين الحكم'**
  String get unassignRefereeBtn;

  /// No description provided for @chooseMatchDateHelp.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخ المباراة'**
  String get chooseMatchDateHelp;

  /// No description provided for @nextBtn.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get nextBtn;

  /// No description provided for @chooseMatchTimeHelp.
  ///
  /// In ar, this message translates to:
  /// **'اختر وقت المباراة'**
  String get chooseMatchTimeHelp;

  /// No description provided for @toubaAppTitle.
  ///
  /// In ar, this message translates to:
  /// **'طوبة'**
  String get toubaAppTitle;

  /// No description provided for @createTournamentBtn.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء بطولة'**
  String get createTournamentBtn;

  /// No description provided for @retryBtn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryBtn;

  /// No description provided for @createFirstTournamentHint.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ أول بطولة بزر «إنشاء بطولة» أدناه'**
  String get createFirstTournamentHint;

  /// No description provided for @noTournamentsInYourAreaYet.
  ///
  /// In ar, this message translates to:
  /// **'لم يُنشئ أحد بطولةً في منطقتك بعد'**
  String get noTournamentsInYourAreaYet;

  /// No description provided for @finishedBadge.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get finishedBadge;

  /// No description provided for @ongoingBadge.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get ongoingBadge;

  /// No description provided for @vXFormat.
  ///
  /// In ar, this message translates to:
  /// **'{format} ضد {format}'**
  String vXFormat(String format);

  /// No description provided for @paidSubscriptionBadge.
  ///
  /// In ar, this message translates to:
  /// **'باشتراك'**
  String get paidSubscriptionBadge;

  /// No description provided for @championX.
  ///
  /// In ar, this message translates to:
  /// **'البطل: {name}'**
  String championX(String name);

  /// No description provided for @cityAndTeamsCount.
  ///
  /// In ar, this message translates to:
  /// **'{city} • {count} فريق'**
  String cityAndTeamsCount(String city, String count);

  /// No description provided for @teamManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الفريق'**
  String get teamManagement;

  /// No description provided for @linkPlayerByCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط لاعب بالكود'**
  String get linkPlayerByCodeTitle;

  /// No description provided for @joinRequestsCountX.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الانضمام ({count})'**
  String joinRequestsCountX(String count);

  /// No description provided for @joinRequestLabel.
  ///
  /// In ar, this message translates to:
  /// **'طلب انضمام'**
  String get joinRequestLabel;

  /// No description provided for @releaseRequestsCountX.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الخروج ({count})'**
  String releaseRequestsCountX(String count);

  /// No description provided for @requestsToLeaveTeam.
  ///
  /// In ar, this message translates to:
  /// **'يطلب الخروج من الفريق'**
  String get requestsToLeaveTeam;

  /// No description provided for @acceptLeave.
  ///
  /// In ar, this message translates to:
  /// **'قبول الخروج'**
  String get acceptLeave;

  /// No description provided for @rosterCountX.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة ({count})'**
  String rosterCountX(String count);

  /// No description provided for @viewShare.
  ///
  /// In ar, this message translates to:
  /// **'عرض/مشاركة'**
  String get viewShare;

  /// No description provided for @rosterManagementHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط شارة «أساسي/احتياط» لنقل اللاعب بين القسمين • اضغط «رقم» لتعديله'**
  String get rosterManagementHint;

  /// No description provided for @noPlayersYetAddWithBtn.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد لاعبون بعد — أضِف لاعبيك بزر «إضافة لاعب»'**
  String get noPlayersYetAddWithBtn;

  /// No description provided for @starters.
  ///
  /// In ar, this message translates to:
  /// **'الأساسيون'**
  String get starters;

  /// No description provided for @noStartersSelectFromSubs.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أساسيون — حدّدهم من الاحتياط'**
  String get noStartersSelectFromSubs;

  /// No description provided for @subs.
  ///
  /// In ar, this message translates to:
  /// **'الاحتياط'**
  String get subs;

  /// No description provided for @noSubs.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد احتياط'**
  String get noSubs;

  /// No description provided for @mainTeamFormation.
  ///
  /// In ar, this message translates to:
  /// **'خطة الفريق الأساسية'**
  String get mainTeamFormation;

  /// No description provided for @currentFormationX.
  ///
  /// In ar, this message translates to:
  /// **'الحالية: {fmt} ({count} لاعبين)'**
  String currentFormationX(String fmt, String count);

  /// No description provided for @notSetChooseCountAndFormation.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحدَّد — اختر عدد اللاعبين والخطة'**
  String get notSetChooseCountAndFormation;

  /// No description provided for @selectBtn.
  ///
  /// In ar, this message translates to:
  /// **'تحديد'**
  String get selectBtn;

  /// No description provided for @noPhotosYetAddUpTo5.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضَف صور بعد — أضِف حتى 5 صور'**
  String get noPhotosYetAddUpTo5;

  /// No description provided for @xOutOf5Photos.
  ///
  /// In ar, this message translates to:
  /// **'{count}/5 صور'**
  String xOutOf5Photos(String count);

  /// No description provided for @editBtn.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editBtn;

  /// No description provided for @formationFormatHint.
  ///
  /// In ar, this message translates to:
  /// **'الصيغة: حارس-دفاع-وسط-هجوم'**
  String get formationFormatHint;

  /// No description provided for @numberForX.
  ///
  /// In ar, this message translates to:
  /// **'رقم {name}'**
  String numberForX(String name);

  /// No description provided for @shirtNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم القميص'**
  String get shirtNumber;

  /// No description provided for @numberX.
  ///
  /// In ar, this message translates to:
  /// **'رقم {num}'**
  String numberX(String num);

  /// No description provided for @noNumber.
  ///
  /// In ar, this message translates to:
  /// **'بلا رقم'**
  String get noNumber;

  /// No description provided for @starter.
  ///
  /// In ar, this message translates to:
  /// **'أساسي'**
  String get starter;

  /// No description provided for @sub.
  ///
  /// In ar, this message translates to:
  /// **'احتياط'**
  String get sub;

  /// No description provided for @linked.
  ///
  /// In ar, this message translates to:
  /// **'مرتبط'**
  String get linked;

  /// No description provided for @notLinked.
  ///
  /// In ar, this message translates to:
  /// **'غير مرتبط'**
  String get notLinked;

  /// No description provided for @positionForX.
  ///
  /// In ar, this message translates to:
  /// **'مركز {name}'**
  String positionForX(String name);

  /// No description provided for @enterPlayerCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل «كود اللاعب» الذي يظهر في ملفه الشخصي:'**
  String get enterPlayerCodeHint;

  /// No description provided for @exampleCode.
  ///
  /// In ar, this message translates to:
  /// **'مثال: A1B2C3D4'**
  String get exampleCode;

  /// No description provided for @linking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الربط...'**
  String get linking;

  /// No description provided for @playerAddedToRoster.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة اللاعب للتشكيلة'**
  String get playerAddedToRoster;

  /// No description provided for @failedToLinkPlayer.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر ربط اللاعب'**
  String get failedToLinkPlayer;

  /// No description provided for @linkBtn.
  ///
  /// In ar, this message translates to:
  /// **'ربط'**
  String get linkBtn;

  /// No description provided for @teamPhotosSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ صور الفريق'**
  String get teamPhotosSaved;

  /// No description provided for @failedToSavePhotos.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الصور'**
  String get failedToSavePhotos;

  /// No description provided for @teamPhotosTitle.
  ///
  /// In ar, this message translates to:
  /// **'صور الفريق'**
  String get teamPhotosTitle;

  /// No description provided for @addUpToMaxPhotos.
  ///
  /// In ar, this message translates to:
  /// **'أضِف حتى {max} صور لفريقك ({count}/{max})'**
  String addUpToMaxPhotos(String max, String count);

  /// No description provided for @savePhotosBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الصور'**
  String get savePhotosBtn;

  /// No description provided for @choosePlayerForSlotX.
  ///
  /// In ar, this message translates to:
  /// **'اختر لاعب الخانة {slotNumber}'**
  String choosePlayerForSlotX(String slotNumber);

  /// No description provided for @chooseTeamFormation.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطة الفريق (حارس-دفاع-وسط-هجوم)'**
  String get chooseTeamFormation;

  /// No description provided for @playersCountX.
  ///
  /// In ar, this message translates to:
  /// **'{count} لاعبين'**
  String playersCountX(String count);

  /// No description provided for @assignPlayerToEachSlot.
  ///
  /// In ar, this message translates to:
  /// **'عيّن لاعباً لكل خانة في التشكيلة'**
  String get assignPlayerToEachSlot;

  /// No description provided for @teamFormationSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تشكيلة الفريق'**
  String get teamFormationSaved;

  /// No description provided for @failedToSaveFormation.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التشكيلة'**
  String get failedToSaveFormation;

  /// No description provided for @formationShareText.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة {teamName} — خطة {formation}'**
  String formationShareText(String teamName, String formation);

  /// No description provided for @failedToShareFormation.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت مشاركة التشكيلة'**
  String get failedToShareFormation;

  /// No description provided for @teamFormation.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة الفريق'**
  String get teamFormation;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @formationPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get formationPlan;

  /// No description provided for @formationWithPlayersCount.
  ///
  /// In ar, this message translates to:
  /// **'{formation} ({count} لاعبين)'**
  String formationWithPlayersCount(String formation, String count);

  /// No description provided for @changeBtn.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get changeBtn;

  /// No description provided for @saveBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveBtn;

  /// No description provided for @numberOfPlayersLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد اللاعبين: '**
  String get numberOfPlayersLabel;

  /// No description provided for @defendersCount.
  ///
  /// In ar, this message translates to:
  /// **'المدافعون'**
  String get defendersCount;

  /// No description provided for @attackersCount.
  ///
  /// In ar, this message translates to:
  /// **'الهجوم'**
  String get attackersCount;

  /// No description provided for @midfieldAndTotalCount.
  ///
  /// In ar, this message translates to:
  /// **'خط الوسط: {mid}  •  المجموع: {total}'**
  String midfieldAndTotalCount(String mid, String total);

  /// No description provided for @confirmFormation.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الخطة'**
  String get confirmFormation;

  /// No description provided for @createTeamTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأسيس فريق جديد'**
  String get createTeamTitle;

  /// No description provided for @teamCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الفريق بنجاح!'**
  String get teamCreatedSuccess;

  /// No description provided for @teamLogoOptional.
  ///
  /// In ar, this message translates to:
  /// **'شعار الفريق (اختياري)'**
  String get teamLogoOptional;

  /// No description provided for @teamNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الفريق'**
  String get teamNameLabel;

  /// No description provided for @pleaseEnterTeamName.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم الفريق'**
  String get pleaseEnterTeamName;

  /// No description provided for @cityOrGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة / المدينة'**
  String get cityOrGovernorate;

  /// No description provided for @areaOptional.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة (اختياري)'**
  String get areaOptional;

  /// No description provided for @areaExample.
  ///
  /// In ar, this message translates to:
  /// **'مثال: حي الجامعة، الكرادة...'**
  String get areaExample;

  /// No description provided for @createTeamBtn.
  ///
  /// In ar, this message translates to:
  /// **'تأسيس الفريق'**
  String get createTeamBtn;

  /// No description provided for @posGoalkeeper.
  ///
  /// In ar, this message translates to:
  /// **'حارس مرمى'**
  String get posGoalkeeper;

  /// No description provided for @posDefender.
  ///
  /// In ar, this message translates to:
  /// **'مدافع'**
  String get posDefender;

  /// No description provided for @posMidfielder.
  ///
  /// In ar, this message translates to:
  /// **'خط وسط'**
  String get posMidfielder;

  /// No description provided for @posForward.
  ///
  /// In ar, this message translates to:
  /// **'مهاجم'**
  String get posForward;

  /// No description provided for @playerNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم اللاعب'**
  String get playerNameLabel;

  /// No description provided for @shirtNumberOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم القميص (اختياري)'**
  String get shirtNumberOptional;

  /// No description provided for @preferredFootOptional.
  ///
  /// In ar, this message translates to:
  /// **'القدم المفضلة (اختياري)'**
  String get preferredFootOptional;

  /// No description provided for @addToRosterBtn.
  ///
  /// In ar, this message translates to:
  /// **'إضافة للتشكيلة'**
  String get addToRosterBtn;

  /// No description provided for @yourRequestEscalatedSoonReviewed.
  ///
  /// In ar, this message translates to:
  /// **'تم تصعيد طلبك للإدارة — سيُراجَع قريباً'**
  String get yourRequestEscalatedSoonReviewed;

  /// No description provided for @confirmPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPasswordTitle;

  /// No description provided for @confirmPasswordToExitDesc.
  ///
  /// In ar, this message translates to:
  /// **'للتأكد أنك صاحب الحساب، أدخل كلمة مرورك قبل طلب الخروج.'**
  String get confirmPasswordToExitDesc;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @incorrectPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة'**
  String get incorrectPassword;

  /// No description provided for @failedToVerifyPassword.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقّق من كلمة المرور'**
  String get failedToVerifyPassword;

  /// No description provided for @updatingLogo.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديث الشعار...'**
  String get updatingLogo;

  /// No description provided for @logoUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الشعار'**
  String get logoUpdatedSuccess;

  /// No description provided for @failedToUpdateLogo.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث الشعار'**
  String get failedToUpdateLogo;

  /// No description provided for @exitRequestSentToCaptain.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الخروج لكابتن فريقك الحالي'**
  String get exitRequestSentToCaptain;

  /// No description provided for @youMustLoginFirst.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول أولاً'**
  String get youMustLoginFirst;

  /// No description provided for @exitTeamRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب الخروج من الفريق'**
  String get exitTeamRequest;

  /// No description provided for @reportThisTeam.
  ///
  /// In ar, this message translates to:
  /// **'بلّغ عن هذا الفريق'**
  String get reportThisTeam;

  /// No description provided for @teamMatchesLost.
  ///
  /// In ar, this message translates to:
  /// **'خسر'**
  String get teamMatchesLost;

  /// No description provided for @teamMatchesDrawn.
  ///
  /// In ar, this message translates to:
  /// **'تعادل'**
  String get teamMatchesDrawn;

  /// No description provided for @youArePlayerInThisTeam.
  ///
  /// In ar, this message translates to:
  /// **'أنت لاعب في هذا الفريق'**
  String get youArePlayerInThisTeam;

  /// No description provided for @exitRequestPendingCaptainReview.
  ///
  /// In ar, this message translates to:
  /// **'طلب خروجك قيد مراجعة كابتن فريقك الحالي'**
  String get exitRequestPendingCaptainReview;

  /// No description provided for @requestEscalatedPendingDecision.
  ///
  /// In ar, this message translates to:
  /// **'طلبك مُصعّد للإدارة — بانتظار القرار'**
  String get requestEscalatedPendingDecision;

  /// No description provided for @requestExitFromX.
  ///
  /// In ar, this message translates to:
  /// **'طلب الخروج من {teamName}'**
  String requestExitFromX(String teamName);

  /// No description provided for @myCurrentTeam.
  ///
  /// In ar, this message translates to:
  /// **'فريقي الحالي'**
  String get myCurrentTeam;

  /// No description provided for @mustExitCurrentTeamBeforeJoining.
  ///
  /// In ar, this message translates to:
  /// **'يجب الخروج من فريقك الحالي أولاً قبل الانضمام'**
  String get mustExitCurrentTeamBeforeJoining;

  /// No description provided for @requestToJoinTeam.
  ///
  /// In ar, this message translates to:
  /// **'طلب انضمام للفريق'**
  String get requestToJoinTeam;

  /// No description provided for @rosterWithCount.
  ///
  /// In ar, this message translates to:
  /// **'التشكيلة ({count})'**
  String rosterWithCount(String count);

  /// No description provided for @pointsByTournament.
  ///
  /// In ar, this message translates to:
  /// **'النقاط حسب البطولة'**
  String get pointsByTournament;

  /// No description provided for @noPlayersRegisteredYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد لاعبون مسجّلون بعد'**
  String get noPlayersRegisteredYet;

  /// No description provided for @teamHasNotParticipatedInTournamentsYet.
  ///
  /// In ar, this message translates to:
  /// **'لم يشارك الفريق في أي بطولة بعد'**
  String get teamHasNotParticipatedInTournamentsYet;

  /// No description provided for @tournamentFinishedStatus.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get tournamentFinishedStatus;

  /// No description provided for @tournamentLiveStatus.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get tournamentLiveStatus;

  /// No description provided for @pointSingle.
  ///
  /// In ar, this message translates to:
  /// **'نقطة'**
  String get pointSingle;

  /// No description provided for @loadingTeamDetails.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل تفاصيل الفريق...'**
  String get loadingTeamDetails;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث بياناتك بنجاح'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث البيانات'**
  String get profileUpdateError;

  /// No description provided for @loginToViewProfile.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض ملفك'**
  String get loginToViewProfile;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get saveChanges;

  /// No description provided for @playerSportsDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اللاعب الرياضية'**
  String get playerSportsDetails;

  /// No description provided for @playerSportsDetailsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'القدم المفضّلة • الطول • الوزن • العمر • نبذة • معرض الصور'**
  String get playerSportsDetailsSubtitle;

  /// No description provided for @permanentPlayerCode.
  ///
  /// In ar, this message translates to:
  /// **'كود لاعبك الدائم'**
  String get permanentPlayerCode;

  /// No description provided for @giveCodeToCaptain.
  ///
  /// In ar, this message translates to:
  /// **'أعطِ هذا الكود لكابتن الفريق ليضيفك إلى تشكيلته.'**
  String get giveCodeToCaptain;

  /// No description provided for @codeCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الكود'**
  String get codeCopied;

  /// No description provided for @myPlayerCodeShare.
  ///
  /// In ar, this message translates to:
  /// **'كود لاعبي في طوبة: {code}'**
  String myPlayerCodeShare(String code);

  /// No description provided for @codeLinkingHint.
  ///
  /// In ar, this message translates to:
  /// **'بمجرّد أن يضيفك الكابتن بهذا الكود، يرتبط حسابك ببطاقة لاعبك تلقائياً.'**
  String get codeLinkingHint;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير صالح'**
  String get invalidPhoneNumber;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

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

  /// No description provided for @okBtn.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get okBtn;

  /// No description provided for @verifiedPlayer.
  ///
  /// In ar, this message translates to:
  /// **'لاعب موثق'**
  String get verifiedPlayer;

  /// No description provided for @manageChallenges.
  ///
  /// In ar, this message translates to:
  /// **'إدارة التحديات'**
  String get manageChallenges;

  /// No description provided for @stale.
  ///
  /// In ar, this message translates to:
  /// **'متروك'**
  String get stale;

  /// No description provided for @challengeDetailsRow.
  ///
  /// In ar, this message translates to:
  /// **'{city} • متقدّمون: {applicants} • منذ {days} يوم'**
  String challengeDetailsRow(String city, int applicants, int days);

  /// No description provided for @cancelChallengeRequestConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء طلب تحدّي فريق «{team}»؟'**
  String cancelChallengeRequestConfirm(String team);

  /// No description provided for @takeActionOnX.
  ///
  /// In ar, this message translates to:
  /// **'اتخاذ إجراء — {name}'**
  String takeActionOnX(String name);

  /// No description provided for @reviewOnlyAction.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة فقط (بدون عقوبة)'**
  String get reviewOnlyAction;

  /// No description provided for @warnAction.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه (تحذير)'**
  String get warnAction;

  /// No description provided for @negativeRatingAction.
  ///
  /// In ar, this message translates to:
  /// **'تقييم سلبي (خصم نقاط)'**
  String get negativeRatingAction;

  /// No description provided for @banAction.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get banAction;

  /// No description provided for @dismissReportAction.
  ///
  /// In ar, this message translates to:
  /// **'رفض البلاغ'**
  String get dismissReportAction;

  /// No description provided for @replyNoteOptional.
  ///
  /// In ar, this message translates to:
  /// **'رد/ملاحظة (اختياري)'**
  String get replyNoteOptional;

  /// No description provided for @executeActionBtn.
  ///
  /// In ar, this message translates to:
  /// **'تنفيذ الإجراء'**
  String get executeActionBtn;

  /// No description provided for @executingAction.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تنفيذ الإجراء...'**
  String get executingAction;

  /// No description provided for @actionExecuted.
  ///
  /// In ar, this message translates to:
  /// **'تم تنفيذ الإجراء'**
  String get actionExecuted;

  /// No description provided for @failedToExecuteAction.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ الإجراء'**
  String get failedToExecuteAction;

  /// No description provided for @allLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In ar, this message translates to:
  /// **'معلّق'**
  String get pendingLabel;

  /// No description provided for @reviewedLabel.
  ///
  /// In ar, this message translates to:
  /// **'تمت المراجعة'**
  String get reviewedLabel;

  /// No description provided for @reviewedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مُراجَع'**
  String get reviewedStatus;

  /// No description provided for @dismissedLabel.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get dismissedLabel;

  /// No description provided for @noReports.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بلاغات'**
  String get noReports;

  /// No description provided for @takeActionLong.
  ///
  /// In ar, this message translates to:
  /// **'اتخاذ إجراء (حظر/تنبيه/تقييم)'**
  String get takeActionLong;

  /// No description provided for @dismissBtn.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get dismissBtn;

  /// No description provided for @searchError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في البحث: {error}'**
  String searchError(String error);

  /// No description provided for @updateFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحديث: {error}'**
  String updateFailed(String error);

  /// No description provided for @searchByPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث برقم الهاتف (مثال: +964...)'**
  String get searchByPhoneHint;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج بحث'**
  String get noSearchResults;

  /// No description provided for @roleX.
  ///
  /// In ar, this message translates to:
  /// **'الدور: {role}'**
  String roleX(String role);

  /// No description provided for @additionalPermissions.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحيات الإضافية:'**
  String get additionalPermissions;

  /// No description provided for @tournamentOrganizer.
  ///
  /// In ar, this message translates to:
  /// **'منظم بطولات'**
  String get tournamentOrganizer;

  /// No description provided for @allowsCreatingTournaments.
  ///
  /// In ar, this message translates to:
  /// **'يسمح بإنشاء وإدارة البطولات'**
  String get allowsCreatingTournaments;

  /// No description provided for @allowsEnteringResults.
  ///
  /// In ar, this message translates to:
  /// **'يسمح بإدخال نتائج المباريات المعين لها'**
  String get allowsEnteringResults;

  /// No description provided for @noBanners.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات — أضف أول إعلان'**
  String get noBanners;

  /// No description provided for @newBannerBtn.
  ///
  /// In ar, this message translates to:
  /// **'إعلان جديد'**
  String get newBannerBtn;

  /// No description provided for @deleteBannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإعلان'**
  String get deleteBannerTitle;

  /// No description provided for @deleteBannerBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا الإعلان نهائياً؟'**
  String get deleteBannerBody;

  /// No description provided for @newBanner.
  ///
  /// In ar, this message translates to:
  /// **'إعلان جديد'**
  String get newBanner;

  /// No description provided for @editBanner.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإعلان'**
  String get editBanner;

  /// No description provided for @bannerTitleOptional.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (اختياري)'**
  String get bannerTitleOptional;

  /// No description provided for @bannerDescOptional.
  ///
  /// In ar, this message translates to:
  /// **'الوصف / التفاصيل (اختياري)'**
  String get bannerDescOptional;

  /// No description provided for @governorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get governorate;

  /// No description provided for @phoneOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف (اختياري)'**
  String get phoneOptional;

  /// No description provided for @whatsappOptional.
  ///
  /// In ar, this message translates to:
  /// **'واتساب (مع رمز الدولة، اختياري)'**
  String get whatsappOptional;

  /// No description provided for @facebookLinkOptional.
  ///
  /// In ar, this message translates to:
  /// **'رابط فيسبوك (اختياري)'**
  String get facebookLinkOptional;

  /// No description provided for @instagramLinkOptional.
  ///
  /// In ar, this message translates to:
  /// **'رابط إنستغرام (اختياري)'**
  String get instagramLinkOptional;

  /// No description provided for @targetUrlOptional.
  ///
  /// In ar, this message translates to:
  /// **'رابط الموقع عند النقر (اختياري)'**
  String get targetUrlOptional;

  /// No description provided for @displayOrder.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الظهور'**
  String get displayOrder;

  /// No description provided for @extraImages.
  ///
  /// In ar, this message translates to:
  /// **'صور إضافية'**
  String get extraImages;

  /// No description provided for @chooseBannerImage.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة الإعلان'**
  String get chooseBannerImage;

  /// No description provided for @failedToSaveBanner.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الإعلان'**
  String get failedToSaveBanner;

  /// No description provided for @bannerWithoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان'**
  String get bannerWithoutTitle;

  /// No description provided for @orderX.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب: {order}'**
  String orderX(int order);

  /// No description provided for @forceReleaseTitle.
  ///
  /// In ar, this message translates to:
  /// **'فكّ ارتباط قسري'**
  String get forceReleaseTitle;

  /// No description provided for @forceReleaseBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُفكّ ارتباط اللاعب من فريقه الحالي ويصبح حرّاً للانضمام لفريق آخر. متابعة؟'**
  String get forceReleaseBody;

  /// No description provided for @forceReleaseBtn.
  ///
  /// In ar, this message translates to:
  /// **'فكّ الارتباط'**
  String get forceReleaseBtn;

  /// No description provided for @forceReleaseForcedBtn.
  ///
  /// In ar, this message translates to:
  /// **'فكّ الارتباط قسرياً'**
  String get forceReleaseForcedBtn;

  /// No description provided for @playerReleasedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم فكّ ارتباط اللاعب'**
  String get playerReleasedSuccess;

  /// No description provided for @noEscalatedDisputes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نزاعات مصعّدة'**
  String get noEscalatedDisputes;

  /// No description provided for @playerWantsToLeaveTeam.
  ///
  /// In ar, this message translates to:
  /// **'يطلب الخروج من فريق: {team}'**
  String playerWantsToLeaveTeam(String team);

  /// No description provided for @captainRejectedEscalated.
  ///
  /// In ar, this message translates to:
  /// **'رفض الكابتن الطلب وصعّده اللاعب للإدارة'**
  String get captainRejectedEscalated;

  /// No description provided for @approvedGrantedReferee.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة ومنح صفة الحكم'**
  String get approvedGrantedReferee;

  /// No description provided for @rejectedApplication.
  ///
  /// In ar, this message translates to:
  /// **'تم الرفض'**
  String get rejectedApplication;

  /// No description provided for @noPendingRefereeApps.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات تحكيم معلّقة'**
  String get noPendingRefereeApps;

  /// No description provided for @requestToRefereeIn.
  ///
  /// In ar, this message translates to:
  /// **'يطلب التحكيم في: {tournament}'**
  String requestToRefereeIn(String tournament);

  /// No description provided for @approveBtn.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get approveBtn;

  /// No description provided for @failedToSaveSettings.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الإعداد'**
  String get failedToSaveSettings;

  /// No description provided for @tournamentsSection.
  ///
  /// In ar, this message translates to:
  /// **'قسم البطولات'**
  String get tournamentsSection;

  /// No description provided for @showHideTournaments.
  ///
  /// In ar, this message translates to:
  /// **'إظهار/إخفاء تبويب البطولات لكل المستخدمين'**
  String get showHideTournaments;

  /// No description provided for @noNews.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أخبار — أضف أول خبر'**
  String get noNews;

  /// No description provided for @newNewsBtn.
  ///
  /// In ar, this message translates to:
  /// **'خبر جديد'**
  String get newNewsBtn;

  /// No description provided for @deleteNewsTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الخبر'**
  String get deleteNewsTitle;

  /// No description provided for @deleteNewsBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا الخبر نهائياً؟'**
  String get deleteNewsBody;

  /// No description provided for @newNews.
  ///
  /// In ar, this message translates to:
  /// **'خبر جديد'**
  String get newNews;

  /// No description provided for @editNews.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخبر'**
  String get editNews;

  /// No description provided for @publishedLabel.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get publishedLabel;

  /// No description provided for @hiddenLabel.
  ///
  /// In ar, this message translates to:
  /// **'مخفي'**
  String get hiddenLabel;

  /// No description provided for @newsStatsX.
  ///
  /// In ar, this message translates to:
  /// **'❤ {likes}  •  ↗ {shares}  •  {status}'**
  String newsStatsX(int likes, int shares, String status);

  /// No description provided for @enterNewsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان الخبر'**
  String get enterNewsTitle;

  /// No description provided for @newsTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get newsTitleLabel;

  /// No description provided for @newsBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'نص الخبر'**
  String get newsBodyLabel;

  /// No description provided for @failedToSaveNews.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الخبر'**
  String get failedToSaveNews;

  /// No description provided for @activationCodesTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكواد التفعيل'**
  String get activationCodesTitle;

  /// No description provided for @settingsCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsCardTitle;

  /// No description provided for @freeTrialDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'مدة التجربة المجانية (أيام)'**
  String get freeTrialDaysLabel;

  /// No description provided for @activationWhatsappLabel.
  ///
  /// In ar, this message translates to:
  /// **'واتساب التفعيل (مثال: 9647xx)'**
  String get activationWhatsappLabel;

  /// No description provided for @saveSettingsBtn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإعدادات'**
  String get saveSettingsBtn;

  /// No description provided for @settingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات'**
  String get settingsSaved;

  /// No description provided for @failedToSaveHighPermission.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ (يتطلّب صلاحية مدير أعلى)'**
  String get failedToSaveHighPermission;

  /// No description provided for @generateCodesTitle.
  ///
  /// In ar, this message translates to:
  /// **'توليد أكواد'**
  String get generateCodesTitle;

  /// No description provided for @durationLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get durationLabel;

  /// No description provided for @countLabel.
  ///
  /// In ar, this message translates to:
  /// **'العدد'**
  String get countLabel;

  /// No description provided for @notesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get notesOptional;

  /// No description provided for @generateBtn.
  ///
  /// In ar, this message translates to:
  /// **'توليد'**
  String get generateBtn;

  /// No description provided for @generatedXCodes.
  ///
  /// In ar, this message translates to:
  /// **'تم توليد {count} كود'**
  String generatedXCodes(int count);

  /// No description provided for @failedToGenerate.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التوليد'**
  String get failedToGenerate;

  /// No description provided for @codesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأكواد'**
  String get codesLabel;

  /// No description provided for @noCodesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد بعد'**
  String get noCodesYet;

  /// No description provided for @copyTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copyTooltip;

  /// No description provided for @unlockTooltip.
  ///
  /// In ar, this message translates to:
  /// **'فكّ القفل'**
  String get unlockTooltip;

  /// No description provided for @month1Label.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get month1Label;

  /// No description provided for @months3Label.
  ///
  /// In ar, this message translates to:
  /// **'3 أشهر'**
  String get months3Label;

  /// No description provided for @months6Label.
  ///
  /// In ar, this message translates to:
  /// **'6 أشهر'**
  String get months6Label;

  /// No description provided for @yearLabel.
  ///
  /// In ar, this message translates to:
  /// **'سنة'**
  String get yearLabel;

  /// No description provided for @editTournamentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البطولة'**
  String get editTournamentTitle;

  /// No description provided for @tournamentCoverImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة البطولة'**
  String get tournamentCoverImage;

  /// No description provided for @tournamentCupImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة الكأس'**
  String get tournamentCupImage;

  /// No description provided for @tournamentNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم البطولة'**
  String get tournamentNameLabel;

  /// No description provided for @tournamentPrizesOptional.
  ///
  /// In ar, this message translates to:
  /// **'الجوائز (اختياري)'**
  String get tournamentPrizesOptional;

  /// No description provided for @tournamentSponsorOptional.
  ///
  /// In ar, this message translates to:
  /// **'اسم الراعي (اختياري)'**
  String get tournamentSponsorOptional;

  /// No description provided for @freeTournament.
  ///
  /// In ar, this message translates to:
  /// **'بطولة مجانية'**
  String get freeTournament;

  /// No description provided for @openToAllTeams.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة لكل الفرق'**
  String get openToAllTeams;

  /// No description provided for @entryFeeInfo.
  ///
  /// In ar, this message translates to:
  /// **'رسوم/تواصل الدخول (للعرض)'**
  String get entryFeeInfo;

  /// No description provided for @failedToSaveTournament.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ التعديلات'**
  String get failedToSaveTournament;

  /// No description provided for @tournamentFinishedWinner.
  ///
  /// In ar, this message translates to:
  /// **'منتهية • البطل: {winner}'**
  String tournamentFinishedWinner(String winner);

  /// No description provided for @tournamentOngoingCity.
  ///
  /// In ar, this message translates to:
  /// **'جارية • {city}'**
  String tournamentOngoingCity(String city);

  /// No description provided for @updatedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم التحديث بنجاح'**
  String get updatedSuccessfully;

  /// No description provided for @addDistrict.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منطقة'**
  String get addDistrict;

  /// No description provided for @editDistrict.
  ///
  /// In ar, this message translates to:
  /// **'تعديل منطقة'**
  String get editDistrict;

  /// No description provided for @nameArabic.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (عربي)'**
  String get nameArabic;

  /// No description provided for @nameEnglish.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (إنجليزي)'**
  String get nameEnglish;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteDistrictX.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف {name}؟'**
  String confirmDeleteDistrictX(String name);

  /// No description provided for @noDistricts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مناطق. اضغط على + لإضافة منطقة.'**
  String get noDistricts;

  /// No description provided for @districtsOfCity.
  ///
  /// In ar, this message translates to:
  /// **'مناطق: {city}'**
  String districtsOfCity(String city);

  /// No description provided for @addGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'إضافة محافظة'**
  String get addGovernorate;

  /// No description provided for @editGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'تعديل محافظة'**
  String get editGovernorate;

  /// No description provided for @manageGovernoratesTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المحافظات'**
  String get manageGovernoratesTitle;

  /// No description provided for @importIraqTooltip.
  ///
  /// In ar, this message translates to:
  /// **'استيراد كل العراق'**
  String get importIraqTooltip;

  /// No description provided for @importConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاستيراد'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حقن كافة محافظات ومناطق العراق. هل أنت متأكد؟'**
  String get importConfirmBody;

  /// No description provided for @importBtn.
  ///
  /// In ar, this message translates to:
  /// **'استيراد'**
  String get importBtn;

  /// No description provided for @importSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستيراد بنجاح'**
  String get importSuccessTitle;

  /// No description provided for @importSuccessBody.
  ///
  /// In ar, this message translates to:
  /// **'تم جلب جميع محافظات ومناطق العراق.'**
  String get importSuccessBody;

  /// No description provided for @errorX.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {error}'**
  String errorX(String error);

  /// No description provided for @noGovernorates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محافظات. اضغط على زر التحميل لاستيراد العراق.'**
  String get noGovernorates;

  /// No description provided for @confirmDeleteCityX.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف {name} وجميع مناطقها؟'**
  String confirmDeleteCityX(String name);
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
      <String>['ar', 'en', 'ku'].contains(locale.languageCode);

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
    case 'ku':
      return AppLocalizationsKu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
