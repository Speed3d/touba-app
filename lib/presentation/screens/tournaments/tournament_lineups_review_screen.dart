import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/tournament_lineup_model.dart';
import '../../../data/repositories/tournament_lineup_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../widgets/core/pitch_formation_view.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../players/player_detail_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: مراجعة المنظّم لتشكيلات البطولة (بند 8). يعرض تشكيلة كل فريق على
/// الملعب + الاحتياط، ويقبلها أو يرفضها (مع ملاحظة). الإشعار للكابتن عبر CF.
class TournamentLineupsReviewScreen extends StatefulWidget {
  final String tournamentId;
  // 📝 HINT AR: المنظّم/الأدمن يقبل/يرفض؛ غيره يرى التشكيلات للقراءة فقط (بند 2).
  final bool canManage;
  const TournamentLineupsReviewScreen({
    super.key,
    required this.tournamentId,
    this.canManage = false,
  });

  @override
  State<TournamentLineupsReviewScreen> createState() =>
      _TournamentLineupsReviewScreenState();
}

class _TournamentLineupsReviewScreenState
    extends State<TournamentLineupsReviewScreen> {
  late Future<List<TournamentLineupModel>> _future;
  // 📝 HINT AR: تشكيلات يعيد المنظّم البتّ بها (أُظهر أزرارها بعد «تغيير القرار»).
  final Set<String> _editing = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // 📝 HINT AR: فتح صفحة اللاعب عند الضغط عليه على الملعب (بند 2) — يجلب سجله الكامل.
  Future<void> _openPlayer(String playerId) async {
    if (playerId.isEmpty) return;
    final repo = context.read<PlayerRepository>();
    try {
      final p = await repo.getPlayerById(playerId);
      if (!mounted) return;
      Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: p)));
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToOpenPlayerProfile);
    }
  }

  Future<List<TournamentLineupModel>> _load() => context
      .read<TournamentLineupRepository>()
      .getLineupsForTournament(widget.tournamentId);

  void _reload() => setState(() => _future = _load());

  Future<void> _review(TournamentLineupModel l, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<TournamentLineupRepository>();
    String? note;
    if (status == 'rejected') {
      note = await _askNote();
      if (note == null) return; // أُلغي
    }
    try {
      await repo.review(l.id, status, note: note);
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          status == 'approved' ? AppLocalizations.of(context)!.lineupApprovedMsg : AppLocalizations.of(context)!.lineupRejectedMsg));
      _editing.remove(l.id); // أعد إخفاء الأزرار بعد القرار
      _reload();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToUpdateStatus));
    }
  }

  Future<String?> _askNote() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectionReasonOptional),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.rejectionReasonExample,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(AppLocalizations.of(context)!.rejectLineupBtn)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reviewLineupsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: FutureBuilder<List<TournamentLineupModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final lineups = snap.data ?? [];
            if (lineups.isEmpty) {
              return ToobaEmptyState(
                icon: Icons.groups_outlined,
                title: AppLocalizations.of(context)!.noLineupsSentYet,
                subtitle: AppLocalizations.of(context)!.lineupsWillAppearHereWhenSent,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: lineups.map(_lineupCard).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _lineupCard(TournamentLineupModel l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, label) = l.isApproved
        ? (Colors.green, AppLocalizations.of(context)!.approvedStatus)
        : l.isRejected
            ? (Colors.red, AppLocalizations.of(context)!.rejectedStatus)
            : (Colors.blue, AppLocalizations.of(context)!.pendingReviewStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l.teamName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.formationX(l.formation ?? "—"),
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 10),
            // الملعب (الأساسيون بترتيب الخانات) — الضغط على لاعب يفتح صفحته.
            PitchFormationView(
              players: l.starters,
              formation: l.formation,
              bySlotOrder: true,
              onSlotTap: (i) {
                if (i < l.starters.length) _openPlayer(l.starters[i].playerId);
              },
            ),
            const SizedBox(height: 10),
            if (l.subs.isNotEmpty) ...[
              Text(AppLocalizations.of(context)!.subsLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: l.subs
                    .map((s) => ActionChip(
                          label: Text(s.name,
                              style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _openPlayer(s.playerId),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (l.isRejected && l.reviewNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(AppLocalizations.of(context)!.yourNoteX(l.reviewNote!),
                    style: const TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic)),
              ),
            // 📝 HINT AR: بند 1 — بعد البتّ تختفي أزرار القبول/الرفض ويظهر «تغيير
            // القرار» (للطوارئ). أثناء «قيد المراجعة» أو بعد «تغيير القرار» تظهر.
            if (widget.canManage &&
                (l.isPending || _editing.contains(l.id)))
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _review(l, 'approved'),
                      icon: const Icon(Icons.check,
                          size: 18, color: Colors.green),
                      label: Text(AppLocalizations.of(context)!.acceptBtn,
                          style: const TextStyle(color: Colors.green)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _review(l, 'rejected'),
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.red),
                      label: Text(AppLocalizations.of(context)!.rejectBtn,
                          style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                ],
              )
            else if (widget.canManage)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _editing.add(l.id)),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(AppLocalizations.of(context)!.changeDecisionBtn,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
