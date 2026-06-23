import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/tournament_lineup_model.dart';
import '../../../data/repositories/tournament_lineup_repository.dart';
import '../../widgets/core/pitch_formation_view.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: مراجعة المنظّم لتشكيلات البطولة (بند 8). يعرض تشكيلة كل فريق على
/// الملعب + الاحتياط، ويقبلها أو يرفضها (مع ملاحظة). الإشعار للكابتن عبر CF.
class TournamentLineupsReviewScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentLineupsReviewScreen({super.key, required this.tournamentId});

  @override
  State<TournamentLineupsReviewScreen> createState() =>
      _TournamentLineupsReviewScreenState();
}

class _TournamentLineupsReviewScreenState
    extends State<TournamentLineupsReviewScreen> {
  late Future<List<TournamentLineupModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
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
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          status == 'approved' ? 'قُبلت التشكيلة' : 'رُفضت التشكيلة'));
      _reload();
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر تحديث الحالة'));
    }
  }

  Future<String?> _askNote() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض (اختياري)'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          decoration: const InputDecoration(
              hintText: 'مثال: نقص في عدد الأساسيين',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('رفض التشكيلة')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة التشكيلات'), centerTitle: true),
      body: FutureBuilder<List<TournamentLineupModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lineups = snap.data ?? [];
          if (lineups.isEmpty) {
            return const ToobaEmptyState(
              icon: Icons.groups_outlined,
              title: 'لا توجد تشكيلات مُرسَلة بعد',
              subtitle: 'ستظهر هنا تشكيلات الكباتن عند إرسالها',
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
    );
  }

  Widget _lineupCard(TournamentLineupModel l) {
    final (color, label) = l.isApproved
        ? (Colors.green, 'مقبولة')
        : l.isRejected
            ? (Colors.red, 'مرفوضة')
            : (Colors.blue, 'قيد المراجعة');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            Text('الخطة: ${l.formation ?? "—"}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 10),
            // الملعب (الأساسيون بترتيب الخانات)
            PitchFormationView(
              players: l.starters,
              formation: l.formation,
              bySlotOrder: true,
            ),
            const SizedBox(height: 10),
            if (l.subs.isNotEmpty) ...[
              const Text('الاحتياط:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: l.subs
                    .map((s) => Chip(
                          label: Text(s.name,
                              style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (l.isRejected && l.reviewNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('ملاحظتك: ${l.reviewNote}',
                    style: const TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic)),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        l.isApproved ? null : () => _review(l, 'approved'),
                    icon: const Icon(Icons.check, size: 18,
                        color: Colors.green),
                    label: const Text('قبول',
                        style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        l.isRejected ? null : () => _review(l, 'rejected'),
                    icon:
                        const Icon(Icons.close, size: 18, color: Colors.red),
                    label: const Text('رفض',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
