import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';


import 'presentation/cubits/theme_cubit.dart';
import 'presentation/cubits/locale_cubit.dart';

import 'package:firebase_core/firebase_core.dart';
import 'data/services/auth/auth_service.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/screens/auth/auth_wrapper.dart';
import 'data/repositories/team_repository.dart';
import 'presentation/cubits/team/team_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PopularFootballApp());
}

class PopularFootballApp extends StatelessWidget {
  const PopularFootballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(
          create: (_) => AuthCubit(
            authService: AuthService(),
            userRepository: UserRepository(),
          ),
        ),
        BlocProvider(
          create: (_) => TeamCubit(TeamRepository(), UserRepository())..fetchTeams(),
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
                home: const AuthWrapper(),
              );
            },
          );
        },
      ),
    );
  }
}
