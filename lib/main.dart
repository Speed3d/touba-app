import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'presentation/screens/main/main_screen.dart';
import 'presentation/cubits/theme_cubit.dart';
import 'presentation/cubits/locale_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
                home: const MainScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
