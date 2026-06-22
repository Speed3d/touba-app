import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import '../../cubits/team/team_manage_cubit.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/release_request_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../tournaments/tournament_details_screen.dart';
import 'team_management_screen.dart';
import '../players/player_detail_screen.dart';
import '../reports/submit_report_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: صفحة الفريق — معلومات + إحصائيات + التشكيلة (سجلات اللاعبين).
class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  // 📝 HINT AR: عضوية المُشاهد — فريقه الحالي (إن كان لاعباً مرتبطاً) لتحديد
  // أزرار الانضمام/الخروج (تدفّق: خروج إلزامي ثم انضمام).
  String? _myPlayerId;
  String? _myCurrentTeamId;
  String? _myCurrentTeamName;
  ReleaseRequestModel? _myRelease; // أحدث طلب خروج لي (إن وُجد)
  late final Future<List<TournamentModel>> _tournamentsFuture;

  @override
  void initState() {
    super.initState();
    context.read<TeamCubit>().fetchTeamDetails(widget.teamId);
    _resolveMyMembership();
    _tournamentsFuture =
        context.read<TournamentRepository>().getTournamentsByTeam(widget.teamId);
  }

  Future<void> _resolveMyMembership() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final user = auth.user;
    if (user.linkedPlayerId == null || user.linkedPlayerId!.isEmpty) return;
    final playerRepo = context.read<PlayerRepository>();
    final teamRepo = context.read<TeamRepository>();
    try {
      final player = await playerRepo.getPlayerById(user.linkedPlayerId!);
      String? teamName;
      ReleaseRequestModel? release;
      if (player.currentTeamId.isNotEmpty) {
        try {
          final t = await teamRepo.getTeamById(player.currentTeamId);
          teamName = t.name;
        } catch (_) {}
        try {
          release = await teamRepo.getMyLatestReleaseRequest(player.id);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _myPlayerId = player.id;
        _myCurrentTeamId = player.currentTeamId;
        _myCurrentTeamName = teamName;
        _myRelease = release;
      });
    } catch (_) {}
  }

  Future<void> _escalateRelease() async {
    if (_myRelease == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final teamRepo = context.read<TeamRepository>();
    try {
      await teamRepo.escalateReleaseRequest(_myRelease!.id);
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          'تم تصعيد طلبك للإدارة — سيُراجَع قريباً'));
      if (mounted) {
        setState(() => _myRelease = null);
      }
      _resolveMyMembership();
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر التصعيد'));
    }
  }

  Future<void> _requestRelease(UserModel user) async {
    if (_myPlayerId == null ||
        _myCurrentTeamId == null ||
        _myCurrentTeamId!.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final teamRepo = context.read<TeamRepository>();
    try {
      await teamRepo.requestRelease(
        playerId: _myPlayerId!,
        teamId: _myCurrentTeamId!,
        teamName: _myCurrentTeamName ?? '',
        userId: user.id,
        userName: user.name,
      );
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          'تم إرسال طلب الخروج لكابتن فريقك الحالي'));
    } catch (e) {
      messenger.showSnackBar(ToobaSnackBar.buildError(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = context.watch<AuthCubit>().state;
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    return BlocConsumer<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamActionSuccess) {
          ToobaSnackBar.success(context, state.message);
        } else if (state is TeamError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is TeamLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (state is TeamDetailsLoaded && state.team.id == widget.teamId) {
          final team = state.team;
          final players = state.players;

          final isMyTeam =
              currentUser != null && team.captainId == currentUser.id;
          // 📝 HINT AR: «لاعب عادي» = ليس أدمن ولا كابتن. الأدمن/الكابتن لا
          // ينضمّون. حالات العضوية: عضو هنا / في فريق آخر / حرّ.
          final isPlayerUser = currentUser != null &&
              !isMyTeam &&
              !currentUser.isAdmin &&
              !currentUser.isCaptain;
          final amMemberHere =
              _myCurrentTeamId != null && _myCurrentTeamId == team.id;
          final amInAnotherTeam = _myCurrentTeamId != null &&
              _myCurrentTeamId!.isNotEmpty &&
              _myCurrentTeamId != team.id;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(team.name),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              actions: [
                if (!isMyTeam)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val != 'report') return;
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ToobaSnackBar.info(context, 'يجب تسجيل الدخول أولاً');
                        return;
                      }
                      Navigator.push(
                        context,
                        ToobaRoute.to(SubmitReportScreen(
                            targetType: ReportTargetType.team,
                            targetId: team.id,
                            targetName: team.name,
                          ),
                        ),
                      );
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, color: Colors.red,
                                size: 18),
                            SizedBox(width: 8),
                            Text('بلّغ عن هذا الفريق',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Hero(
                      tag: 'team_logo_${team.id}',
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: team.logoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: team.logoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (c, u, e) =>
                                      const Icon(Icons.shield, size: 60),
                                )
                              : Icon(Icons.shield,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    team.name,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        team.area != null && team.area!.isNotEmpty
                            ? '${team.city} • ${team.area}'
                            : team.city,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard(context, 'لعب', team.stats.played.toString()),
                      _statCard(context, 'فاز', team.stats.wins.toString()),
                      _statCard(context, 'خسر', team.stats.losses.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 📝 HINT AR: حالة اللاعب في هذا الفريق.
                  if (isPlayerUser && amMemberHere)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.green),
                          SizedBox(width: 8),
                          Text('أنت لاعب في هذا الفريق',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  // اللاعب في فريق آخر: خروج إلزامي ثم انضمام.
                  if (isPlayerUser && amInAnotherTeam) ...[
                    if (_myRelease?.status == 'pending')
                      _releaseStatusBox(
                          'طلب خروجك قيد مراجعة كابتن فريقك الحالي',
                          Icons.hourglass_top,
                          Colors.blue)
                    else if (_myRelease?.status == 'rejected' &&
                        _myRelease?.escalated == true)
                      _releaseStatusBox('طلبك مُصعّد للإدارة — بانتظار القرار',
                          Icons.gavel, Colors.purple)
                    else if (_myRelease?.status == 'rejected')
                      Column(
                        children: [
                          _releaseStatusBox(
                              'رفض كابتنك طلب الخروج',
                              Icons.cancel,
                              Colors.red),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _escalateRelease,
                              icon: const Icon(Icons.gavel,
                                  color: Colors.purple),
                              label: const Text('تصعيد الطلب للإدارة',
                                  style: TextStyle(color: Colors.purple)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.purple),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _requestRelease(currentUser),
                          icon: const Icon(Icons.logout, color: Colors.orange),
                          label: Text(
                              'طلب الخروج من ${_myCurrentTeamName ?? "فريقي الحالي"}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.orange)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // مُعطّل فعلياً: يجب الخروج أولاً.
                        onPressed: () => ToobaSnackBar.info(context,
                            'يجب الخروج من فريقك الحالي أولاً قبل الانضمام'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('طلب انضمام للفريق',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  // اللاعب الحرّ (بلا فريق): انضمام مباشر.
                  if (isPlayerUser && !amMemberHere && !amInAnotherTeam)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TeamCubit>().requestToJoinTeam(
                                team.id,
                                currentUser.id,
                                currentUser.name,
                              );
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('طلب انضمام للفريق',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (isMyTeam)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 📝 HINT AR: نوفّر TeamManageCubit محلياً لهذه الشاشة.
                          // عند الرجوع نُعيد تحميل تفاصيل الفريق ليظهر أي لاعب
                          // قُبل حديثاً (تحديث التشكيلة وعدّاد اللاعبين).
                          final teamCubit = context.read<TeamCubit>();
                          Navigator.push(
                            context,
                            ToobaRoute.to(BlocProvider(
                              create: (ctx) => TeamManageCubit(
                                ctx.read<TeamRepository>(),
                                ctx.read<PlayerRepository>(),
                                team.id,
                              )..load(),
                              child: const TeamManagementScreen(),
                            )),
                          ).then((_) => teamCubit.fetchTeamDetails(team.id));
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('إدارة الفريق',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (isPlayerUser || isMyTeam) const SizedBox(height: 24),
                  // ── أزرار قابلة للطيّ: التشكيلة + النقاط حسب البطولة ──
                  _expandable(
                    context,
                    icon: Icons.groups,
                    title: 'التشكيلة (${players.length})',
                    initiallyExpanded: true,
                    children: players.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('لا يوجد لاعبون مسجّلون بعد',
                                  style: TextStyle(color: Colors.grey[600])),
                            )
                          ]
                        : players.map((p) => _playerCard(context, p)).toList(),
                  ),
                  const SizedBox(height: 12),
                  _expandable(
                    context,
                    icon: Icons.emoji_events,
                    title: 'النقاط حسب البطولة',
                    initiallyExpanded: false,
                    children: [_tournamentsSection(context, team.id)],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: const Center(child: Text('جاري تحميل تفاصيل الفريق...')),
        );
      },
    );
  }

  // 📝 HINT AR: قسم قابل للطيّ (ExpansionTile) بعنوان وأيقونة.
  Widget _expandable(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: children,
        ),
      ),
    );
  }

  // 📝 HINT AR: نقاط الفريق ومركزه في كل بطولة شارك بها (حساب لحظي من standings).
  Widget _tournamentsSection(BuildContext context, String teamId) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('النقاط حسب البطولة',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<TournamentModel>>(
          future: _tournamentsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final tournaments = snap.data ?? [];
            if (tournaments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('لم يشارك الفريق في أي بطولة بعد',
                    style: TextStyle(color: Colors.grey[600])),
              );
            }
            return Column(
              children:
                  tournaments.map((t) => _tournamentRow(context, t, teamId)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _tournamentRow(
      BuildContext context, TournamentModel t, String teamId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // مركز الفريق ونقاطه من standings (مفروزة مسبقاً من CF).
    int? rank;
    int? points;
    for (var i = 0; i < t.standings.length; i++) {
      final s = Map<String, dynamic>.from(t.standings[i]);
      if (s['teamId'] == teamId) {
        rank = i + 1;
        points = s['points'] ?? 0;
        break;
      }
    }
    final isChampion = t.status == 'finished' && t.winnerTeamId == teamId;

    return GestureDetector(
      onTap: () => _openTournament(context, t.id),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isChampion
                ? Colors.amber
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // المركز
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _rankColor(rank).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: isChampion
                ? const Icon(Icons.emoji_events,
                    color: Colors.amber, size: 22)
                : Text(rank != null ? '#$rank' : '—',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _rankColor(rank))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  t.status == 'finished' ? 'منتهية' : 'جارية',
                  style: TextStyle(
                      fontSize: 12,
                      color: t.status == 'finished'
                          ? Colors.grey
                          : Colors.green),
                ),
              ],
            ),
          ),
          // النقاط
          Column(
            children: [
              Text(points != null ? '$points' : '—',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
              const Text('نقطة', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // 📝 HINT AR: فتح تفاصيل البطولة (بـ TournamentCubit محلّي).
  void _openTournament(BuildContext context, String tournamentId) {
    Navigator.push(
      context,
      ToobaRoute.to(BlocProvider(
        create: (ctx) => TournamentCubit(
          ctx.read<TournamentRepository>(),
          ctx.read<MatchRepository>(),
          ctx.read<TeamRepository>(),
        )..fetchDetails(tournamentId),
        child: TournamentDetailsScreen(tournamentId: tournamentId),
      )),
    );
  }

  Color _rankColor(int? rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.blueGrey;
    if (rank == 3) return Colors.brown;
    return Colors.grey;
  }

  Widget _releaseStatusBox(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _playerCard(BuildContext context, PlayerModel player) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ImageProvider? imageProvider;
    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      if (player.photoUrl!.startsWith('assets/')) {
        imageProvider = AssetImage(player.photoUrl!);
      } else {
        imageProvider = CachedNetworkImageProvider(player.photoUrl!);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          ToobaRoute.to(PlayerDetailScreen(player: player)),
        ),
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Row(
          children: [
            Text(player.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (player.isClaimed) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 14, color: Colors.blue),
            ],
          ],
        ),
        subtitle: Text(player.position),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.shirtNumber != null) ...[
              Text('#${player.shirtNumber}',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(player.careerStats.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
