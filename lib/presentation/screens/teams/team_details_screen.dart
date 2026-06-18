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
import '../../../data/models/report_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<TeamCubit>().fetchTeamDetails(widget.teamId);
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
          // 📝 HINT AR: طلب الانضمام لِلاعب عادي فقط — الأدمن والكابتن لا يطلبون.
          final canJoin = currentUser != null &&
              !isMyTeam &&
              !currentUser.isAdmin &&
              !currentUser.isCaptain;

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
                      _statCard(context, 'نقاط', team.stats.points.toString()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (canJoin)
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
                  if (canJoin || isMyTeam) const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'تشكيلة الفريق (${players.length})',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (players.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('لا يوجد لاعبون مسجّلون بعد',
                          style: TextStyle(color: Colors.grey[600])),
                    )
                  else
                    ...players.map((p) => _playerCard(context, p)),
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
