import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

import 'presentation/cubits/theme_cubit.dart';
import 'presentation/cubits/locale_cubit.dart';
import 'data/services/auth/auth_service.dart';
import 'data/services/preferences_service.dart';
import 'data/services/notification_service.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/team_repository.dart';
import 'data/repositories/player_repository.dart';
import 'data/repositories/tournament_repository.dart';
import 'data/repositories/match_repository.dart';
import 'data/repositories/home_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/challenge_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/tournament_lineup_repository.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/team/team_cubit.dart';
import 'presentation/cubits/tournament/tournament_cubit.dart';
import 'presentation/screens/splash/splash_screen.dart';

// 📝 HINT AR: نسخة واحدة من Analytics تُستخدم للمراقبة وللـ Observer في الراوتر.
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// 📝 HINT AR: معالج FCM في وضع الخلفية/الإنهاء — يجب أن يكون دالة عليا (top-level).
// FCM يعرض الإشعار تلقائياً في شريط النظام؛ لا نحتاج منطقاً إضافياً هنا.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // FCM handles display automatically for background/terminated state
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 📝 HINT AR: تهيئة Firebase بقيم صريحة من firebase_options.dart (touba-3ds).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 📝 HINT AR: يجب تسجيل معالج الخلفية قبل runApp.
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // 📝 HINT AR: تهيئة التفضيلات المحلية قبل runApp ليقرأها الثيم/اللغة فوراً.
  await PreferencesService.init();

  // 📝 HINT AR: تهيئة خدمة الإشعارات (FCM + Local Notifications + حفظ التوكن).
  await NotificationService.instance.initialize();

  // 📝 HINT AR: App Check — يحمي خلفية Firebase من الاستدعاءات خارج التطبيق.
  // في التطوير نستخدم مزوّد debug (للحصول على رمز محلي)، وفي الإصدار
  // Play Integrity (أندرويد) و App Attest (iOS). نلفّه بـ try لئلا يعطّل الإقلاع.
  try {
    // 📝 HINT AR: نستخدم المعاملات المتوافقة مع النسخة المثبّتة (0.4.1+4)؛
    // الأسماء الأحدث (providerAndroid/Apple) تتطلّب أنواع مزوّدات مختلفة.
    // ignore: deprecated_member_use
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      // ignore: deprecated_member_use
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  } catch (_) {
    // تجاهل أي فشل في App Check حتى لا يمنع تشغيل التطبيق.
  }

  // 📝 HINT AR: Crashlytics — التقاط كل أخطاء Flutter وغير Flutter تلقائياً.
  // نعطّل الجمع في وضع التصحيح لتفادي ضجيج تقارير التطوير.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const PopularFootballApp());
}

class PopularFootballApp extends StatelessWidget {
  const PopularFootballApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 📝 HINT AR: نوفّر المستودعات عبر RepositoryProvider ليصل إليها أي شاشة/Cubit
    // بـ context.read<...Repository>() (يحل مشكلة عدم توفّر UserRepository سابقاً).
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => UserRepository()),
        RepositoryProvider(create: (_) => TeamRepository()),
        RepositoryProvider(create: (_) => PlayerRepository()),
        RepositoryProvider(create: (_) => TournamentRepository()),
        RepositoryProvider(create: (_) => MatchRepository()),
        RepositoryProvider(create: (_) => HomeRepository()),
        RepositoryProvider(create: (_) => ChatRepository()),
        RepositoryProvider(create: (_) => ChallengeRepository()),
        RepositoryProvider(create: (_) => SubscriptionRepository()),
        RepositoryProvider(create: (_) => TournamentLineupRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(
            create: (context) => AuthCubit(
              authService: AuthService(),
              userRepository: context.read<UserRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => TeamCubit(
              context.read<TeamRepository>(),
              context.read<PlayerRepository>(),
            )..fetchTeams(),
          ),
          BlocProvider(
            create: (context) => TournamentCubit(
              context.read<TournamentRepository>(),
              context.read<MatchRepository>(),
              context.read<TeamRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeData>(
          builder: (context, theme) {
            return BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                return MaterialApp(
                  title: 'طوبة',
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  locale: locale,
                  // 📝 HINT AR: مراقبة تنقّل الشاشات تلقائياً في Analytics.
                  navigatorObservers: [
                    FirebaseAnalyticsObserver(analytics: analytics),
                  ],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('ar'),
                    Locale('en'),
                  ],
                  home: const SplashScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
