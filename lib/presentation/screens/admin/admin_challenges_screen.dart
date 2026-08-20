import '../../../core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: إدارة التحديات (للأدمن) — إلغاء الطلبات **المتروكة** (مفتوحة بلا
/// متقدّمين منذ عدّة أيام، لم يُلغها الكابتن) أو أي طلب مفتوح. القاعدة تسمح للأدمن
/// بتحديث حالة التحدّي إلى ملغى.
class AdminChallengesScreen extends StatelessWidget {
  const AdminChallengesScreen({super.key});
  static const _staleDays = 3;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChallengeRepository>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageChallenges),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: StreamBuilder<List<ChallengeModel>>(
          stream: repo.streamOpen(limit: 100),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.noOpenChallengeRequests,
                      style: TextStyle(color: Colors.grey[600])));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) => _tile(context, list[i], repo),
            );
          },
        ),
      ),
    );
  }

  Widget _tile(
      BuildContext context, ChallengeModel c, ChallengeRepository repo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ageDays = c.createdAt == null
        ? 0
        : DateTime.now().difference(c.createdAt!).inDays;
    final stale = ageDays >= _staleDays && c.applicants.isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      (c.requesterLogo != null && c.requesterLogo!.isNotEmpty)
                          ? ImageHelper.getProvider(c.requesterLogo!)
                          : null,
                  child: (c.requesterLogo == null || c.requesterLogo!.isEmpty)
                      ? const Icon(Icons.shield, size: 16, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.requesterTeamName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (stale)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(AppLocalizations.of(context)!.stale,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                AppLocalizations.of(context)!.challengeDetailsRow(c.city, c.applicants.length, ageDays),
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (c.note != null && c.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(c.note!, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, c, repo),
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: Text(AppLocalizations.of(context)!.cancelRequestBtn,
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, ChallengeModel c, ChallengeRepository repo) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequestBtn),
        content: Text(l10n.cancelChallengeRequestConfirm(c.requesterTeamName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelBtn)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.cancelRequestBtn)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.cancel(c.id);
      messenger.showSnackBar(ToobaSnackBar.buildInfo(l10n.requestCancelledStatus));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError(l10n.failedToCancel));
    }
  }
}
