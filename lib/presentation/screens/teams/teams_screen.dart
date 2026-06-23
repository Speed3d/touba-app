import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      if (!isVisitor) const Tab(text: 'فريقي'),
      const Tab(text: 'الفرق الشعبية'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('الفرق'),
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
                    label: const Text('تأسيس فريق'),
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
          return ToobaEmptyState(
            icon: Icons.shield_outlined,
            title: user.role == 'captain'
                ? 'لا تملك فريقاً بعد'
                : 'لست مسجّلاً في أي فريق',
            subtitle: user.role == 'captain'
                ? 'أسّس فريقك بزر «تأسيس فريق» أدناه'
                : 'انضمّ إلى فريق من تبويب «الفرق الشعبية»',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refreshMyTeam(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [_myTeamCard(team, user, isDark)],
          ),
        );
      },
    );
  }

  Widget _myTeamCard(TeamModel team, UserModel user, bool isDark) {
    final theme = Theme.of(context);
    final isCaptain = team.captainId == user.id;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 📝 HINT AR: الشعار للعرض فقط هنا — تغييره من «عرض وإدارة الفريق».
          CircleAvatar(
            radius: 50,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            backgroundImage: team.logoUrl != null
                ? CachedNetworkImageProvider(team.logoUrl!)
                : null,
            child: team.logoUrl == null
                ? Icon(Icons.shield,
                    size: 50,
                    color: isDark ? Colors.grey[600] : Colors.grey[400])
                : null,
          ),
          const SizedBox(height: 12),
          Text(team.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                  team.area != null && team.area!.isNotEmpty
                      ? '${team.city} • ${team.area}'
                      : team.city,
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          // 📝 HINT AR: صفّان — (لعب/فاز/خسر/تعادل) ليصحّ المجموع، ثم (نقاط/لاعبون).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat('لعب', team.stats.played.toString()),
              _miniStat('فاز', team.stats.wins.toString()),
              _miniStat('خسر', team.stats.losses.toString()),
              _miniStat('تعادل', team.stats.draws.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat('نقاط', team.stats.points.toString()),
              _miniStat('لاعبون', team.playerCount.toString()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                ToobaRoute.to(BlocProvider(
                  create: (ctx) => TeamCubit(
                    ctx.read<TeamRepository>(),
                    ctx.read<PlayerRepository>(),
                  ),
                  child: TeamDetailsScreen(teamId: team.id),
                )),
              ).then((_) => _refreshMyTeam()),
              icon: Icon(isCaptain ? Icons.settings : Icons.visibility),
              label: Text(isCaptain ? 'عرض وإدارة الفريق' : 'عرض الفريق'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // 📝 HINT AR: للكابتن — دخول تحدّيات الفرق (المحادثات صارت زراً في
          // شريط التنقّل السفلي).
          if (isCaptain) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context, ToobaRoute.to(const ChallengesScreen())),
                icon: const Icon(Icons.sports_kabaddi, size: 18),
                label: const Text('تحدّيات الفرق'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          // 📝 HINT AR: للاعب (لا الكابتن) — حالة طلب خروجه إن رُفض + التصعيد.
          if (!isCaptain &&
              user.linkedPlayerId != null &&
              user.linkedPlayerId!.isNotEmpty)
            _releaseStatusInMyTeam(user.linkedPlayerId!),
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
          return _statusBox('طلب خروجك قيد مراجعة الكابتن', Icons.hourglass_top,
              Colors.blue);
        }
        if (r.status == 'rejected' && r.escalated) {
          return _statusBox('طلبك مُصعّد للإدارة — بانتظار القرار', Icons.gavel,
              Colors.purple);
        }
        if (r.status == 'rejected') {
          return Column(
            children: [
              _statusBox(
                  'رفض كابتنك طلب الخروج', Icons.cancel, Colors.red),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _escalate(r.id),
                  icon: const Icon(Icons.gavel, color: Colors.purple),
                  label: const Text('تصعيد الطلب للإدارة',
                      style: TextStyle(color: Colors.purple)),
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
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess('تم تصعيد طلبك للإدارة'));
      _refreshMyTeam();
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر التصعيد'));
    }
  }

  Widget _miniStat(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
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
              hintText: 'ابحث عن فريق...',
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
                  title: 'تعذّر تحميل الفرق',
                  subtitle: state.message,
                  actionLabel: 'إعادة المحاولة',
                  onAction: () => context.read<TeamCubit>().fetchTeams(),
                );
              }
              if (state is TeamsLoaded) {
                final filtered = state.teams.where((team) {
                  return team.name.toLowerCase().contains(_searchQuery) ||
                      team.city.toLowerCase().contains(_searchQuery);
                }).toList();

                if (state.teams.isEmpty) {
                  return const ToobaEmptyState(
                    icon: Icons.shield_outlined,
                    title: 'لا توجد فرق مسجّلة بعد',
                    subtitle: 'لم يُسجَّل أي فريق في المنصة بعد',
                  );
                }
                if (filtered.isEmpty) {
                  return ToobaEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد نتائج',
                    subtitle: 'لا يوجد فريق يطابق "$_searchQuery"',
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
                        _sectionLabel('فريقي'),
                        const SizedBox(height: 8),
                        _teamTile(myTeam, isDark, theme, isMine: true),
                        const SizedBox(height: 12),
                        _sectionLabel('فرق أخرى'),
                        const SizedBox(height: 8),
                        if (others.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('لا توجد فرق أخرى بعد',
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
                ? CachedNetworkImageProvider(team.logoUrl!)
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
                      ? '${team.city} • ${team.area}'
                      : team.city,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.group, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text('${team.playerCount} لاعب',
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
