import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/functions_service.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: شاشة إدارة البلاغات — تعرض كل البلاغات مرتّبة من الأحدث،
/// مع إمكانية تصفيتها بالحالة ومراجعتها أو رفضها مباشرةً.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportStatus? _filter; // null = الكل

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(100);
    if (_filter != null) q = q.where('status', isEqualTo: _filter!.name);
    return q.snapshots();
  }

  Future<void> _updateStatus(String id, ReportStatus status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(id)
        .update({'status': status.name});
  }

  // 📝 HINT AR: نافذة إجراءات الأدمن — رد كتابي + اختيار العقوبة، تستدعي CF.
  Future<void> _openModeration(ReportModel report) async {
    final replyCtrl = TextEditingController();
    String action = 'review';
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget actionTile(String value, String label, IconData icon,
              Color color) {
            final sel = action == value;
            return InkWell(
              onTap: () => setSheet(() => action = value),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sel ? color.withValues(alpha: 0.12) : null,
                  border: Border.all(
                      color: sel ? color : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 10),
                    Text(label,
                        style: TextStyle(
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal)),
                    const Spacer(),
                    if (sel) Icon(Icons.check_circle, color: color, size: 18),
                  ],
                ),
              ),
            );
          }

          final canRate = report.targetType != ReportTargetType.user;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.takeActionOnX(report.targetName),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                actionTile('review', l10n.reviewOnlyAction,
                    Icons.check_circle_outline, Colors.blue),
                actionTile('warn', l10n.warnAction,
                    Icons.warning_amber_rounded, Colors.orange),
                if (canRate)
                  actionTile('negativeRating', l10n.negativeRatingAction,
                      Icons.star_half_rounded, Colors.deepOrange),
                actionTile('ban', l10n.banAction,
                    Icons.block, Colors.red),
                actionTile('dismiss', l10n.dismissReportAction,
                    Icons.cancel_outlined, Colors.grey),
                const SizedBox(height: 12),
                TextField(
                  controller: replyCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.replyNoteOptional,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.executeActionBtn),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed != true) return;
    try {
      messenger.showSnackBar(ToobaSnackBar.buildInfo(l10n.executingAction));
      await FunctionsService().moderateReport(
        reportId: report.id,
        action: action,
        adminReply: replyCtrl.text.trim().isEmpty ? null : replyCtrl.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(l10n.actionExecuted));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          ToobaSnackBar.buildError(e.message ?? l10n.failedToExecuteAction));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(l10n.failedToExecuteAction));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: Column(
          children: [
            // شريط تصفية الحالة
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _filterChip(context, AppLocalizations.of(context)!.allLabel, null),
                  const SizedBox(width: 8),
                  _filterChip(context, AppLocalizations.of(context)!.pendingLabel, ReportStatus.pending),
                  const SizedBox(width: 8),
                  _filterChip(context, AppLocalizations.of(context)!.reviewedLabel, ReportStatus.reviewed),
                  const SizedBox(width: 8),
                  _filterChip(context, AppLocalizations.of(context)!.dismissedLabel, ReportStatus.dismissed),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _buildStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 72, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context)!.noReports,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final report =
                          ReportModel.fromFirestore(docs[i]);
                      return _ReportCard(
                        report: report,
                        onReview: () =>
                            _updateStatus(report.id, ReportStatus.reviewed),
                        onDismiss: () =>
                            _updateStatus(report.id, ReportStatus.dismissed),
                        onModerate: () => _openModeration(report),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      BuildContext context, String label, ReportStatus? status) {
    final selected = _filter == status;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onReview;
  final VoidCallback onDismiss;
  final VoidCallback onModerate;

  const _ReportCard({
    required this.report,
    required this.onReview,
    required this.onDismiss,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // أيقونة نوع الهدف
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _typeColor(report.targetType).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon(report.targetType),
                    color: _typeColor(report.targetType), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.targetType.getLabel(context)}: ${report.targetName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      report.reason.getLabel(context),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _StatusBadge(report.status),
            ],
          ),
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              report.description,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // أزرار الإجراء — تظهر فقط للبلاغات المعلّقة
          if (report.status == ReportStatus.pending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(AppLocalizations.of(context)!.dismissBtn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.reviewedLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onModerate,
                icon: const Icon(Icons.gavel, size: 18, color: Colors.red),
                label: Text(AppLocalizations.of(context)!.takeActionLong,
                    style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(ReportTargetType t) {
    switch (t) {
      case ReportTargetType.player:
        return Colors.blue;
      case ReportTargetType.team:
        return Colors.teal;
      case ReportTargetType.user:
        return Colors.purple;
    }
  }

  IconData _typeIcon(ReportTargetType t) {
    switch (t) {
      case ReportTargetType.player:
        return Icons.sports_soccer;
      case ReportTargetType.team:
        return Icons.shield_outlined;
      case ReportTargetType.user:
        return Icons.person_outline;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        label = AppLocalizations.of(context)!.pendingLabel;
        break;
      case ReportStatus.reviewed:
        color = Colors.green;
        label = AppLocalizations.of(context)!.reviewedStatus;
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        label = AppLocalizations.of(context)!.dismissedLabel;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
