import re

with open('lib/presentation/screens/home/home_screen.dart', 'r') as f:
    c = f.read()

# Make sure PlayerRepository and PlayerDetailScreen are imported
if "import '../../../data/repositories/player_repository.dart';" not in c:
    c = c.replace("import '../../../data/repositories/home_repository.dart';", "import '../../../data/repositories/home_repository.dart';\nimport '../../../data/repositories/player_repository.dart';\nimport '../players/player_detail_screen.dart';\nimport '../teams/teams_screen.dart';")


# We need to change `_quickActionsSection` to use FutureBuilder
old_quick_actions = r"Widget _quickActionsSection\(bool isDark\) \{.*?return SingleChildScrollView.*?\}\);"
new_quick_actions = """Widget _quickActionsSection(bool isDark) {
    return FutureBuilder<bool>(
      future: _tournamentsEnabled,
      builder: (context, snap) {
        final showTournaments = snap.data ?? true;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _quickActionChip(
                title: 'المباريات',
                icon: '⚽',
                isDark: isDark,
                onTap: () => Navigator.push(context, ToobaRoute.to(const MatchesScreen())),
              ),
              if (showTournaments)
                _quickActionChip(
                  title: 'البطولات',
                  icon: '🏆',
                  isDark: isDark,
                  onTap: () => Navigator.push(context, ToobaRoute.to(const TournamentsScreen())),
                ),
              _quickActionChip(
                title: 'الفرق',
                icon: '🛡️',
                isDark: isDark,
                onTap: () => Navigator.push(context, ToobaRoute.to(const TeamsScreen())),
              ),
              _quickActionChip(
                title: 'الأخبار',
                icon: '📰',
                isDark: isDark,
                onTap: () => Navigator.push(context, ToobaRoute.to(const NewsScreen())),
              ),
              _quickActionChip(
                title: 'بطاقتي',
                icon: '🃏',
                isDark: isDark,
                onTap: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! AuthAuthenticated) {
                    ToobaSnackBar.info(context, 'يجب تسجيل الدخول أولاً');
                    return;
                  }
                  final pid = authState.user.linkedPlayerId;
                  if (pid == null || pid.isEmpty) {
                    ToobaSnackBar.info(context, 'لا تملك بطاقة لاعب حالياً');
                    return;
                  }
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  try {
                    final pModel = await context.read<PlayerRepository>().getPlayerById(pid);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (pModel != null) {
                      Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: pModel)));
                    } else {
                      ToobaSnackBar.error(context, 'اللاعب غير موجود');
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ToobaSnackBar.error(context, 'حدث خطأ أثناء جلب البطاقة');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }"""

# Fix ToobaSnackBar if missing
if "import '../../../core/utils/tooba_snack_bar.dart';" not in c:
    c = c.replace("import '../../../app/theme/app_colors.dart';", "import '../../../app/theme/app_colors.dart';\nimport '../../../core/utils/tooba_snack_bar.dart';")

c = re.sub(old_quick_actions, new_quick_actions, c, flags=re.DOTALL)

with open('lib/presentation/screens/home/home_screen.dart', 'w') as f:
    f.write(c)

