import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../widgets/core/tooba_card.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_screen.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: قائمة البطولات الحقيقية (من Firestore) بدل البيانات الوهمية.
class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TournamentCubit>().fetchTournaments();
  }

  void _openDetails(TournamentModel t) {
    Navigator.push(
      context,
      ToobaRoute.to(BlocProvider(
        create: (ctx) => TournamentCubit(
          ctx.read<TournamentRepository>(),
          ctx.read<MatchRepository>(),
          ctx.read<TeamRepository>(),
        )..fetchDetails(t.id),
        child: TournamentDetailsScreen(tournamentId: t.id),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canManage = user != null &&
        (user.isAdmin || user.adminPermissions.contains('organizer'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('طوبة',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: false,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                ToobaRoute.to(const CreateTournamentScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إنشاء بطولة'),
            )
          : null,
      body: BlocBuilder<TournamentCubit, TournamentState>(
        builder: (context, state) {
          if (state is TournamentError) {
            return ToobaEmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'تعذّر تحميل البطولات',
              subtitle: state.message,
              actionLabel: 'إعادة المحاولة',
              onAction: () =>
                  context.read<TournamentCubit>().fetchTournaments(),
            );
          }
          if (state is TournamentsLoaded) {
            final ongoing =
                state.tournaments.where((t) => t.status == 'ongoing').toList();
            final others =
                state.tournaments.where((t) => t.status != 'ongoing').toList();

            if (state.tournaments.isEmpty) {
              return ToobaEmptyState(
                icon: LucideIcons.trophy,
                title: 'لا توجد بطولات بعد',
                subtitle: canManage
                    ? 'أنشئ أول بطولة بزر «إنشاء بطولة» أدناه'
                    : 'لم يُنشئ أحد بطولةً في منطقتك بعد',
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<TournamentCubit>().fetchTournaments(),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (ongoing.isNotEmpty) ...[
                    _header('بطولات جارية'),
                    ...ongoing.map((t) => _ongoingBanner(theme, t)),
                    const SizedBox(height: 16),
                  ],
                  if (others.isNotEmpty) ...[
                    _header('بطولات أخرى'),
                    ...others.map((t) => _tournamentRow(t)),
                  ],
                ],
              ),
            );
          }
          // Shimmer loading
          return ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _header('بطولات جارية'),
              const ToobaShimmerBanner(),
              const SizedBox(height: 16),
              _header('بطولات أخرى'),
              const ToobaShimmerList(count: 3, tileHeight: 72),
            ],
          );
        },
      ),
    );
  }

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _ongoingBanner(ThemeData theme, TournamentModel t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _openDetails(t),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1877F2), Color(0xFF0C5EBF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(LucideIcons.trophy,
                    size: 120, color: Colors.white.withValues(alpha: 0.1)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('جارية',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const Spacer(),
                    Text(t.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${t.city} • ${t.teamIds.length} فريق',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tournamentRow(TournamentModel t) {
    final finished = t.status == 'finished';
    return ToobaCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => _openDetails(t),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: finished
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(LucideIcons.trophy,
                color: finished ? Colors.amber.shade700 : Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(t.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (finished) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('منتهية',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (finished && t.winnerTeamName != null)
                  Row(
                    children: [
                      const Text('🏆 ', style: TextStyle(fontSize: 13)),
                      Flexible(
                        child: Text('البطل: ${t.winnerTeamName}',
                            style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )
                else
                  Text('${t.city} • ${t.teamIds.length} فريق',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronLeft, color: Colors.grey),
        ],
      ),
    );
  }
}
