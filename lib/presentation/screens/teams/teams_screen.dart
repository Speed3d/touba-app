import '../../../core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import '../players/player_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/release_request_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import 'create_team_screen.dart';
import 'team_details_screen.dart';
import '../challenges/challenges_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: شاشة الفرق — تبويبان: «فريقي» (فريق المستخدم) و«الفرق الشعبية»
/// (بقية الفرق). الزائر يرى «الفرق الشعبية» فقط. زر «تأسيس فريق» يظهر فقط
/// لكابتن لا يملك فريقاً (قاعدة فريق واحد لكل كابتن).
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 📝 HINT AR: فريق المستخدم (كابتن أو لاعب مرتبط) — يُحلّ مرة ويُعاد عند الحاجة.
  Future<TeamModel?>? _myTeamFuture;
  String? _resolvedForUid;

  @override
  void initState() {
    super.initState();
    final state = context.read<TeamCubit>().state;
    if (state is! TeamsLoaded) {
      context.read<TeamCubit>().fetchTeams();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 📝 HINT AR: يحلّ فريق المستخدم حسب دوره: الكابتن عبر captainId، واللاعب
  // المرتبط عبر سجله (currentTeamId).
  Future<TeamModel?> _resolveMyTeam(UserModel user) async {
    final teamRepo = context.read<TeamRepository>();
    final playerRepo = context.read<PlayerRepository>();
    if (user.role == 'captain') {
      return teamRepo.getTeamByCaptain(user.id);
    }
    if (user.linkedPlayerId != null && user.linkedPlayerId!.isNotEmpty) {
      try {
        final player = await playerRepo.getPlayerById(user.linkedPlayerId!);
        if (player.currentTeamId.isEmpty) return null;
        return teamRepo.getTeamById(player.currentTeamId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<TeamModel?> _myTeam(UserModel user) {
    // نُعيد الحلّ إذا تغيّر المستخدم أو لم يُحلّ بعد.
    if (_myTeamFuture == null || _resolvedForUid != user.id) {
      _resolvedForUid = user.id;
      _myTeamFuture = _resolveMyTeam(user);
    }
    return _myTeamFuture!;
  }

  void _refreshMyTeam() {
    setState(() => _myTeamFuture = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isVisitor = user == null;

    final tabs = <Tab>[
      if (!isVisitor) Tab(text: AppLocalizations.of(context)!.myTeamTab),
      Tab(text: AppLocalizations.of(context)!.popularTeamsTab),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.teamsTitle),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            tabs: tabs,
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: TabBarView(
          children: [
            if (!isVisitor) _myTeamTab(user, isDark),
            _popularTeamsTab(isDark, theme, user),
          ],
        ),
        // 📝 HINT AR: زر التأسيس فقط لكابتن بلا فريق.
        floatingActionButton: (user != null && user.role == 'captain')
            ? FutureBuilder<TeamModel?>(
                future: _myTeam(user),
                builder: (context, snap) {
                  final hasTeam = snap.data != null;
                  if (hasTeam) return const SizedBox.shrink();
                  return FloatingActionButton.extended(
                    onPressed: () {
                      final teamCubit = context.read<TeamCubit>();
                      Navigator.push(
                        context,
                        ToobaRoute.to(const CreateTeamScreen()),
                      ).then((_) {
                        _refreshMyTeam();
                        teamCubit.fetchTeams();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.createTeam),
                  );
                },
              )
            : null,
      ),
    );
  }

  // ── تبويب «فريقي» ──────────────────────────────────────────────────────
  Widget _myTeamTab(UserModel user, bool isDark) {
    return FutureBuilder<TeamModel?>(
      future: _myTeam(user),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerList(count: 1, tileHeight: 200);
        }
        final team = snap.data;
        if (team == null) {
          return _buildNoTeamState(user, isDark);
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshMyTeam(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [_myTeamCard(team, user, isDark)],
          ),
        );
      },
    );
  }

  Widget _buildNoTeamState(UserModel user, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // 📝 HINT AR: صورة الملعب
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13261C) : const Color(0xFFE6F9EE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00D166).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // رسمة الملعب المبسطة
                Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 1.5,
                          height: 120,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
                const Center(child: Text('⚽', style: TextStyle(fontSize: 40))),
                Positioned(
                  bottom: 14,
                  child: Text(AppLocalizations.of(context)!.yourPitchAwaits,
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.dontHaveTeamYet,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text(
              user.role == 'captain'
                  ? AppLocalizations.of(context)!.createTeamSubtitleCaptain
                  : AppLocalizations.of(context)!.joinExistingTeamSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 32),
          if (user.role == 'captain') ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  ToobaRoute.to(const CreateTeamScreen()),
                ).then((_) {
                  if (!mounted) return;
                  _refreshMyTeam();
                  context.read<TeamCubit>().fetchTeams();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D166), Color(0xFF00924A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D166).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(AppLocalizations.of(context)!.createYourTeamNow,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: () {
              DefaultTabController.of(context).animateTo(1);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1826) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[300]!),
              ),
              alignment: Alignment.center,
              child: Text(AppLocalizations.of(context)!.joinExistingTeamBtn,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _myTeamCard(TeamModel team, UserModel user, bool isDark) {
    final theme = Theme.of(context);
    final isCaptain = team.captainId == user.id;
    return Column(
      children: [
        // 📝 HINT AR: بانر الفريق العلوي
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1A3050), Color(0xFF0D1826)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE6F0FF), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
          child: Column(
            children: [
              Hero(
                tag: 'team_logo_${team.id}',
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4A800).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: isDark ? const Color(0xFF1A3050) : Colors.white,
                    image: team.logoUrl != null
                        ? DecorationImage(
                            image: ImageHelper.getProvider(team.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: team.logoUrl == null
                      ? Center(
                          child: Text('🦅', style: const TextStyle(fontSize: 44)))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(team.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    team.area != null && team.area!.isNotEmpty
                        ? AppLocalizations.of(context)!.cityAndAreaX(team.city, team.area!)
                        : team.city,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // الإحصائيات باللون الذهبي
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBadge(AppLocalizations.of(context)!.rating, team.ratingPoints.toString(), true),
                  const SizedBox(width: 12),
                  _statBadge(AppLocalizations.of(context)!.playedCount, team.stats.played.toString(), false),
                  const SizedBox(width: 12),
                  _statBadge(AppLocalizations.of(context)!.winsCount, team.stats.wins.toString(), false),
                  const SizedBox(width: 12),
                  _statBadge(AppLocalizations.of(context)!.tournamentsCount, team.badges.length.toString(), false),
                ],
              ),
            ],
          ),
        ),
        
        // 📝 HINT AR: أزرار الإجراءات السريعة
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    ToobaRoute.to(BlocProvider(
                      create: (ctx) => TeamCubit(
                        ctx.read<TeamRepository>(),
                        ctx.read<PlayerRepository>(),
                      ),
                      child: TeamDetailsScreen(teamId: team.id),
                    )),
                  ).then((_) => _refreshMyTeam()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A3050) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isCaptain ? AppLocalizations.of(context)!.manageTeam : AppLocalizations.of(context)!.viewTeam,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
              ),
              if (isCaptain) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context, ToobaRoute.to(const ChallengesScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A3050) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.challengesTab,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 📝 HINT AR: التشكيلة (اللاعبون)
        if (team.roster.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.roster,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(AppLocalizations.of(context)!.playerCountX(team.playerCount.toString()),
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: team.roster.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = team.roster[index];
              return GestureDetector(
                onTap: () {
                  // We must fetch the PlayerModel first
                  showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
                  context.read<PlayerRepository>().getPlayerById(player.playerId).then((pModel) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: pModel)));
                  }).catchError((_) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.playerNotFound)));
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1826) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? const Color(0xFF1A3050) : Colors.grey[200],
                        backgroundImage: player.photoUrl != null
                            ? ImageHelper.getProvider(player.photoUrl!)
                            : null,
                        child: player.photoUrl == null
                            ? Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(player.position,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.black54)),
                          ],
                        ),
                      ),
                      if (player.shirtNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            player.shirtNumber.toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        if (!isCaptain &&
            user.linkedPlayerId != null &&
            user.linkedPlayerId!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _releaseStatusInMyTeam(user.linkedPlayerId!),
          ),
      ],
    );
  }

  Widget _statBadge(String title, String value, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFD4A800).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isPrimary ? const Color(0xFFD4A800).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: isPrimary ? const Color(0xFFD4A800) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(title,
              style: TextStyle(
                  color: isPrimary ? const Color(0xFFD4A800).withValues(alpha: 0.8) : Colors.white54,
                  fontSize: 10)),
        ],
      ),
    );
  }

  // 📝 HINT AR: يعرض في «فريقي» تنبيه رفض الخروج + زر التصعيد للإدارة.
  Widget _releaseStatusInMyTeam(String playerId) {
    return FutureBuilder<ReleaseRequestModel?>(
      future: context.read<TeamRepository>().getMyLatestReleaseRequest(playerId),
      builder: (context, snap) {
        final r = snap.data;
        if (r == null) return const SizedBox.shrink();
        if (r.status == 'pending') {
          return _statusBox(AppLocalizations.of(context)!.yourExitRequestPending, Icons.hourglass_top,
              Colors.blue);
        }
        if (r.status == 'rejected' && r.escalated) {
          return _statusBox(AppLocalizations.of(context)!.yourRequestEscalated, Icons.gavel,
              Colors.purple);
        }
        if (r.status == 'rejected') {
          return Column(
            children: [
              _statusBox(
                  AppLocalizations.of(context)!.captainRejectedYourRequest, Icons.cancel, Colors.red),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _escalate(r.id),
                  icon: const Icon(Icons.gavel, color: Colors.purple),
                  label: Text(AppLocalizations.of(context)!.escalateRequestToAdmin,
                      style: const TextStyle(color: Colors.purple)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _statusBox(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: color),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _escalate(String releaseId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TeamRepository>().escalateReleaseRequest(releaseId);
      if (!mounted) return;
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.requestEscalatedSuccess));
      _refreshMyTeam();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToEscalate));
    }
  }

  // ── تبويب «الفرق الشعبية» ──────────────────────────────────────────────
  Widget _popularTeamsTab(bool isDark, ThemeData theme, UserModel? user) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchForTeam,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<TeamCubit, TeamState>(
            builder: (context, state) {
              if (state is TeamLoading && state is! TeamsLoaded) {
                return const ToobaShimmerList(count: 7, tileHeight: 76);
              }
              if (state is TeamError) {
                return ToobaEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: AppLocalizations.of(context)!.failedToLoadTeams,
                  subtitle: state.message,
                  actionLabel: AppLocalizations.of(context)!.retry,
                  onAction: () => context.read<TeamCubit>().fetchTeams(),
                );
              }
              if (state is TeamsLoaded) {
                final filtered = state.teams.where((team) {
                  return team.name.toLowerCase().contains(_searchQuery) ||
                      team.city.toLowerCase().contains(_searchQuery);
                }).toList();

                if (state.teams.isEmpty) {
                  return ToobaEmptyState(
                    icon: Icons.shield_outlined,
                    title: AppLocalizations.of(context)!.noTeamsRegisteredYet,
                    subtitle: AppLocalizations.of(context)!.noTeamsRegisteredInPlatform,
                  );
                }
                if (filtered.isEmpty) {
                  return ToobaEmptyState(
                    icon: Icons.search_off_rounded,
                    title: AppLocalizations.of(context)!.noResultsFound,
                    subtitle: AppLocalizations.of(context)!.noTeamMatchesX(_searchQuery),
                  );
                }

                // 📝 HINT AR: فصل فريق الكابتن — «فريقي» أعلى ثم «فرق أخرى».
                TeamModel? myTeam;
                if (user != null && user.role == 'captain') {
                  for (final t in state.teams) {
                    if (t.captainId == user.id) {
                      myTeam = t;
                      break;
                    }
                  }
                }
                final showMine = myTeam != null && _searchQuery.isEmpty;
                final others = showMine
                    ? filtered.where((t) => t.id != myTeam!.id).toList()
                    : filtered;

                return RefreshIndicator(
                  onRefresh: () => context.read<TeamCubit>().fetchTeams(),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (showMine) ...[
                        _sectionLabel(AppLocalizations.of(context)!.myTeamTab),
                        const SizedBox(height: 8),
                        _teamTile(myTeam, isDark, theme, isMine: true),
                        const SizedBox(height: 12),
                        _sectionLabel(AppLocalizations.of(context)!.otherTeamsLabel),
                        const SizedBox(height: 8),
                        if (others.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(AppLocalizations.of(context)!.noOtherTeamsYet,
                                style: TextStyle(color: Colors.grey[600])),
                          ),
                      ],
                      ...others.map((t) => _teamTile(t, isDark, theme)),
                    ],
                  ),
                );
              }
              return const ToobaShimmerList(count: 5, tileHeight: 76);
            },
          ),
        ),
      ],
    );
  }

  // 📝 HINT AR: عنوان قسم داخل قائمة الفرق الشعبية («فريقي» / «فرق أخرى»).
  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _teamTile(TeamModel team, bool isDark, ThemeData theme,
      {bool isMine = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMine
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Hero(
          tag: 'team_logo_${team.id}',
          child: CircleAvatar(
            radius: 28,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            backgroundImage: team.logoUrl != null
                ? ImageHelper.getProvider(team.logoUrl!)
                : null,
            child: team.logoUrl == null
                ? Icon(Icons.shield,
                    color: isDark ? Colors.grey[600] : Colors.grey[400])
                : null,
          ),
        ),
        title: Text(team.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(Icons.location_on,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  team.area != null && team.area!.isNotEmpty
                      ? AppLocalizations.of(context)!.cityAndAreaX(team.city, team.area!)
                      : team.city,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.group, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(AppLocalizations.of(context)!.playerCountX(team.playerCount.toString()),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            ToobaRoute.to(BlocProvider(
              create: (ctx) => TeamCubit(
                ctx.read<TeamRepository>(),
                ctx.read<PlayerRepository>(),
              ),
              child: TeamDetailsScreen(teamId: team.id),
            )),
          ).then((_) => _refreshMyTeam());
        },
      ),
    );
  }
}
