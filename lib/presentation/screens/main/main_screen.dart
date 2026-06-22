import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../home/home_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../teams/teams_screen.dart';
import '../matches/matches_screen.dart';
import '../settings/settings_screen.dart';

/// 📝 HINT AR: الشاشة الجذر بشريط تنقّل. تبويب «البطولات» يظهر/يختفي حسب علم
/// `settings/features.tournamentsEnabled` (يتحكّم به الأدمن من لوحة التحكم).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _TabDef {
  final Widget page;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabDef(this.page, this.icon, this.activeIcon, this.label);
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('features')
          .snapshots(),
      builder: (context, snap) {
        final tournamentsEnabled =
            snap.data?.data()?['tournamentsEnabled'] as bool? ?? true;
        return _buildShell(context, tournamentsEnabled);
      },
    );
  }

  Widget _buildShell(BuildContext context, bool tournamentsEnabled) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // 📝 HINT AR: التبويبات تُبنى ديناميكياً — تُحذف البطولات عند التعطيل.
    final tabs = <_TabDef>[
      _TabDef(const HomeScreen(), Icons.home_outlined, Icons.home, l10n.home),
      if (tournamentsEnabled)
        _TabDef(const TournamentsScreen(), Icons.emoji_events_outlined,
            Icons.emoji_events, l10n.tournaments),
      _TabDef(const TeamsScreen(), Icons.shield_outlined, Icons.shield,
          l10n.teams),
      _TabDef(const MatchesScreen(), Icons.sports_soccer_outlined,
          Icons.sports_soccer, l10n.matches),
      _TabDef(const SettingsScreen(), Icons.settings_outlined, Icons.settings,
          l10n.settings),
    ];
    final index = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: tabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color:
                  isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
            showUnselectedLabels: true,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            elevation: 0,
            items: tabs
                .map((t) => BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(t.icon),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(t.activeIcon),
                      ),
                      label: t.label,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
