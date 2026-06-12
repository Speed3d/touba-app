// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tooba';

  @override
  String get tournaments => 'Tournaments';

  @override
  String get teams => 'Teams';

  @override
  String get matches => 'Matches';

  @override
  String get profile => 'Profile';

  @override
  String get createTeam => 'Create Team';

  @override
  String get addPlayer => 'Add Player';

  @override
  String get enterScore => 'Enter Score';

  @override
  String get standings => 'Standings';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get welcomeMessage =>
      'Welcome to Tooba, the amateur football platform';
}
