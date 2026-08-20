import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/report_model.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// شاشة تقديم بلاغ عن لاعب أو فريق.
/// المعاملات: [targetType] نوع الهدف، [targetId] معرّفه، [targetName] اسمه للعرض.
class SubmitReportScreen extends StatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String targetName;

  const SubmitReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  ReportReason _reason = ReportReason.offensiveContent;
  bool _loading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      final report = ReportModel(
        id: '',
        reporterId: uid,
        targetType: widget.targetType,
        targetId: widget.targetId,
        targetName: widget.targetName,
        reason: _reason,
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('reports')
          .add(report.toFirestore());
      if (mounted) {
        ToobaSnackBar.success(context, AppLocalizations.of(context)!.reportSentSuccess);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ToobaSnackBar.error(context, AppLocalizations.of(context)!.reportSentFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? AppColors.surfaceDark : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.submitReportTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // معلومات الهدف
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.targetType == ReportTargetType.team
                              ? Icons.shield_outlined
                              : Icons.person_outline,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.reportAboutTarget(widget.targetType.getLabel(context)),
                                style: TextStyle(
                                    fontSize: 12, color: isDark ? Colors.white60 : Colors.grey),
                              ),
                              Text(
                                widget.targetName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // سبب البلاغ
                  DropdownButtonFormField<ReportReason>(
                    initialValue: _reason,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.reportReasonLabel,
                      prefixIcon: const Icon(Icons.flag_outlined),
                      border: border,
                      enabledBorder: border,
                      filled: true,
                      fillColor: fill,
                    ),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: ReportReason.values
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r.getLabel(context))))
                        .toList(),
                    onChanged: (v) => setState(() => _reason = v!),
                  ),
                  const SizedBox(height: 16),

                  // وصف تفصيلي
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.problemDescriptionOptional,
                      hintText: AppLocalizations.of(context)!.explainProblemInDetailHint,
                      border: border,
                      enabledBorder: border,
                      filled: true,
                      fillColor: fill,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.falseReportsWarning,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context)!.submitReportBtn,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
