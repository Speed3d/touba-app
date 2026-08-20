import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/referee_application_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: مراجعة طلبات التحكيم (للأدمن). الموافقة تمنح صفة الحكم تلقائياً
/// (عبر Cloud Function) وتُشعر المنظّم ليضيف المتقدّم في بطولته.
class AdminRefereeApplicationsScreen extends StatelessWidget {
  const AdminRefereeApplicationsScreen({super.key});

  Future<void> _resolve(
      BuildContext context, String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('referee_applications')
          .doc(id)
          .update({'status': status});
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          status == 'approved' ? l10n.approvedGrantedReferee : l10n.rejectedApplication));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError(l10n.failedToExecuteAction));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TournamentRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminRefereeApplicationsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: StreamBuilder<List<RefereeApplicationModel>>(
          stream: repo.pendingApplicationsStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final apps = snap.data ?? [];
            if (apps.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_outlined, size: 72, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.noPendingRefereeApps,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = apps[i];
                return Card(
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
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.userName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(a.userPhone,
                                      style: TextStyle(
                                          color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.requestToRefereeIn(a.tournamentName),
                            style: TextStyle(
                                fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _resolve(context, a.id, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: const BorderSide(color: Colors.red)),
                                child: Text(AppLocalizations.of(context)!.rejectBtn),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _resolve(context, a.id, 'approved'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(AppLocalizations.of(context)!.approveBtn),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
