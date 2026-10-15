import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router/tooba_route.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../core/utils/tooba_snack_bar.dart';
import '../../../../data/models/tournament_lineup_model.dart';
import '../../../../data/repositories/tournament_lineup_repository.dart';
import '../../../../data/services/functions_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cubits/tournament/tournament_cubit.dart';
import '../../../cubits/tournament/tournament_state.dart';
import '../tournament_lineups_review_screen.dart';

/// 📝 HINT AR: تبويب «الفرق المشاركة» — كل الفرق مع حالة تشكيلتها (لم
/// يُرسل / تم الإرسال / تم التحقق / مرفوضة). الضغط على فريق أرسل يفتح المراجعة
/// وفريق لم يُرسل يفتح نافذة تذكير (للمنظّم).
class TournamentTeamsTab extends StatelessWidget {
  final TournamentDetailsLoaded state;
  final bool canManage;

  const TournamentTeamsTab({
    super.key,
    required this.state,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final t = state.tournament;
    return FutureBuilder<List<TournamentLineupModel>>(
      future: context
          .read<TournamentLineupRepository>()
          .getLineupsForTournament(t.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final byTeam = {
          for (final l in snap.data ?? <TournamentLineupModel>[]) l.teamId: l
        };
        return RefreshIndicator(
          onRefresh: () =>
              context.read<TournamentCubit>().fetchDetails(t.id),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppLocalizations.of(context)!.teamLineupsStatus(t.teamIds.length.toString()),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  canManage
                      ? AppLocalizations.of(context)!.tapToReviewOrRemind
                      : AppLocalizations.of(context)!.tapToViewLineup,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
              if (t.teamIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)!.noParticipatingTeams,
                      style: TextStyle(color: Colors.grey[600])),
                )
              else
                ...t.teamIds.map((id) => _teamStatusCard(
                    context, state, id, byTeam[id], canManage)),
            ],
          ),
        );
      },
    );
  }

  Widget _teamStatusCard(BuildContext context, TournamentDetailsLoaded state,
      String teamId, TournamentLineupModel? lineup, bool canManage) {
    final team = state.teamsById[teamId];
    final name = team?.name ?? '—';
    Color color;
    String label;
    IconData icon;
    if (lineup == null) {
      color = Colors.orange;
      label = AppLocalizations.of(context)!.notSent;
      icon = Icons.hourglass_empty;
    } else if (lineup.isApproved) {
      color = Colors.green;
      label = AppLocalizations.of(context)!.verified;
      icon = Icons.verified;
    } else if (lineup.isRejected) {
      color = Colors.red;
      label = AppLocalizations.of(context)!.rejected;
      icon = Icons.cancel;
    } else {
      color = Colors.blue;
      label = AppLocalizations.of(context)!.sent;
      icon = Icons.send;
    }
    final logo = team?.logoUrl;
    final hasLogo = logo != null && logo.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: hasLogo ? ImageHelper.getProvider(logo) : null,
          child: !hasLogo
              ? Icon(Icons.shield, size: 18, color: Colors.grey.shade400)
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Icon(
            lineup == null && !canManage
                ? Icons.lock_clock
                : Icons.chevron_left,
            color: Colors.grey[400]),
        onTap: () {
          if (lineup != null) {
            Navigator.push(
              context,
              ToobaRoute.to(TournamentLineupsReviewScreen(
                  tournamentId: state.tournament.id, canManage: canManage)),
            );
          } else if (canManage) {
            _remindCaptain(context, state.tournament.id, teamId, name);
          } else {
            ToobaSnackBar.info(context, AppLocalizations.of(context)!.captainNotSentLineup);
          }
        },
      ),
    );
  }

  Future<void> _remindCaptain(BuildContext context, String tournamentId,
      String teamId, String teamName) async {
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.remindTeamX(teamName)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.remindCaptainMessageBody,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.customMessageOptional,
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.sendReminderBtn)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FunctionsService()
          .remindLineup(tournamentId, teamId, ctrl.text.trim());
      if (context.mounted) {
        messenger.showSnackBar(
            ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.reminderSentToCaptainX(teamName)));
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToSendReminder));
      }
    }
  }
}
