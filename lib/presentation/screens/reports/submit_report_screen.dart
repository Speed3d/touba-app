import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../data/models/report_model.dart';
import '../../../core/utils/tooba_snack_bar.dart';

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
        ToobaSnackBar.success(context, 'تم إرسال البلاغ — سيراجعه الفريق قريباً');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ToobaSnackBar.error(context, 'تعذّر إرسال البلاغ — حاول مرة أخرى');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? Colors.grey[900] : Colors.grey[100];
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('تقديم بلاغ'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
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
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
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
                              'بلاغ عن ${widget.targetType.label}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
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
                    labelText: 'سبب البلاغ',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: border,
                    filled: true,
                    fillColor: fill,
                  ),
                  items: ReportReason.values
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r.label)))
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
                    labelText: 'وصف المشكلة (اختياري)',
                    hintText: 'اشرح المشكلة بتفاصيل أكثر...',
                    border: border,
                    filled: true,
                    fillColor: fill,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ملاحظة: البلاغات الكاذبة أو التافهة قد تؤدي إلى تقييد حسابك.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('إرسال البلاغ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
