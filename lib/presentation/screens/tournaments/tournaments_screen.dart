import '../../../core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.toubaAppTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: false,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                ToobaRoute.to(const CreateTournamentScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.createTournamentBtn),
            )
          : null,
      body: BlocBuilder<TournamentCubit, TournamentState>(
        builder: (context, state) {
          if (state is TournamentError) {
            return ToobaEmptyState(
              icon: Icons.wifi_off_rounded,
              title: AppLocalizations.of(context)!.failedToLoadTournaments,
              subtitle: state.message,
              actionLabel: AppLocalizations.of(context)!.retryBtn,
              onAction: () =>
                  context.read<TournamentCubit>().fetchTournaments(),
            );
          }
          if (state is TournamentsLoaded) {
            final ongoing =
                state.tournaments.where((t) => t.status == 'ongoing').toList();
            final finished =
                state.tournaments.where((t) => t.status == 'finished').toList();
            final others = state.tournaments
                .where((t) => t.status != 'ongoing' && t.status != 'finished')
                .toList();

            if (state.tournaments.isEmpty) {
              return ToobaEmptyState(
                icon: Icons.emoji_events,
                title: AppLocalizations.of(context)!.noTournamentsYet,
                subtitle: canManage
                    ? AppLocalizations.of(context)!.createFirstTournamentHint
                    : AppLocalizations.of(context)!.noTournamentsInYourAreaYet,
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<TournamentCubit>().fetchTournaments(),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (ongoing.isNotEmpty) ...[
                    _header(AppLocalizations.of(context)!.ongoingTournaments),
                    ...ongoing.map((t) => _tournamentCard(context, theme, t)),
                    const SizedBox(height: 16),
                  ],
                  if (finished.isNotEmpty) ...[
                    _header(AppLocalizations.of(context)!.finishedTournaments),
                    ...finished.map((t) => _tournamentCard(context, theme, t)),
                    const SizedBox(height: 16),
                  ],
                  if (others.isNotEmpty) ...[
                    _header(AppLocalizations.of(context)!.otherTournaments),
                    ...others.map((t) => _tournamentCard(context, theme, t)),
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
              _header(AppLocalizations.of(context)!.ongoingTournaments),
              const ToobaShimmerBanner(),
              const SizedBox(height: 16),
              _header(AppLocalizations.of(context)!.otherTournaments),
              const ToobaShimmerList(count: 3, tileHeight: 72),
            ],
          );
        },
      ),
    );
  }

  Widget _miniBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  // 📝 HINT AR: كارت بطولة موحّد (نفس الحجم للجارية والمنتهية). المنتهية تأخذ
  // تدرّجاً ذهبياً + شارة «منتهية» + اسم البطل.
  Widget _tournamentCard(BuildContext context, ThemeData theme, TournamentModel t) {
    final finished = t.status == 'finished';
    final gradient = finished
        ? [Colors.amber.shade700, Colors.orange.shade900]
        : const [Color(0xFF1877F2), Color(0xFF0C5EBF)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _openDetails(t),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // 📝 HINT AR: صورة البطولة كخلفية (إن وُجدت) تحت تدرّج معتم.
              image: (t.logoUrl != null && t.logoUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: ImageHelper.getProvider(t.logoUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.45),
                          BlendMode.darken),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(Icons.emoji_events,
                      size: 120, color: Colors.white.withValues(alpha: 0.12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _miniBadge(finished ? AppLocalizations.of(context)!.finishedBadge : AppLocalizations.of(context)!.ongoingBadge),
                          const SizedBox(width: 6),
                          _miniBadge(AppLocalizations.of(context)!.vXFormat(t.playerFormat.toString())),
                          if (!t.isFree) ...[
                            const SizedBox(width: 6),
                            _miniBadge(AppLocalizations.of(context)!.paidSubscriptionBadge),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Text(t.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (finished && t.winnerTeamName != null)
                        Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(AppLocalizations.of(context)!.championX(t.winnerTeamName!),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        )
                      else
                        Text(AppLocalizations.of(context)!.cityAndTeamsCount(t.city, t.teamIds.length.toString()),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
