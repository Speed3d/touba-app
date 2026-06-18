import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../teams/teams_screen.dart';
import '../matches/matches_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const TournamentsScreen(),
    const TeamsScreen(),
    const MatchesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home),
                ),
                label: AppLocalizations.of(context)!.home,
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.emoji_events_outlined),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.emoji_events),
                ),
                label: AppLocalizations.of(context)!.tournaments,
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.shield_outlined),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.shield),
                ),
                label: AppLocalizations.of(context)!.teams,
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.sports_soccer_outlined),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.sports_soccer),
                ),
                label: AppLocalizations.of(context)!.matches,
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.settings_outlined),
                ),
                activeIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.settings),
                ),
                label: AppLocalizations.of(context)!.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
