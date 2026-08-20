import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/activation_code_model.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: لوحة الأدمن للاشتراكات (المرحلة 8): إعدادات (مدة التجربة + واتساب)
/// + توليد أكواد (1/3/6/12 شهر) + قائمة الأكواد (نسخ/حذف/فكّ قفل). التوليد كتابة
/// أدمن مباشرة؛ الاستهلاك عبر CF. (حفظ الإعدادات يتطلّب صلاحية مدير أعلى.)
class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  final _trialCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _duration = 1;
  int _count = 1;
  bool _savingSettings = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _trialCtrl.dispose();
    _whatsappCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final s = await context.read<SubscriptionRepository>().getSettings();
      if (!mounted) return;
      setState(() {
        _trialCtrl.text = s.freeTrialDays.toString();
        _whatsappCtrl.text = s.whatsapp;
      });
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    setState(() => _savingSettings = true);
    try {
      await context.read<SubscriptionRepository>().updateSettings(
            freeTrialDays: int.tryParse(_trialCtrl.text.trim()) ?? 14,
            whatsapp: _whatsappCtrl.text.trim(),
          );
      if (mounted) ToobaSnackBar.success(context, AppLocalizations.of(context)!.settingsSaved);
    } catch (_) {
      if (mounted) {
        ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToSaveHighPermission);
      }
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  Future<void> _generate() async {
    final st = context.read<AuthCubit>().state;
    final adminId = st is AuthAuthenticated ? st.user.id : null;
    if (adminId == null) return;
    setState(() => _generating = true);
    try {
      final codes = await context.read<SubscriptionRepository>().generateCodes(
            adminId: adminId,
            durationMonths: _duration,
            count: _count,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) {
        _notesCtrl.clear();
        ToobaSnackBar.success(context, AppLocalizations.of(context)!.generatedXCodes(codes.length));
      }
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToGenerate);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SubscriptionRepository>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.activationCodesTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _settingsCard(),
            const SizedBox(height: 16),
            _generateCard(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.codesLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            StreamBuilder<List<ActivationCodeModel>>(
              stream: repo.streamCodes(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()));
                }
                final codes = snap.data!;
                if (codes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(AppLocalizations.of(context)!.noCodesYet,
                        style: TextStyle(color: Colors.grey[600])),
                  );
                }
                return Column(children: codes.map(_codeTile).toList());
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.settingsCardTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _trialCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.freeTrialDaysLabel,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _whatsappCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.activationWhatsappLabel,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _savingSettings ? null : _saveSettings,
              child: _savingSettings
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.saveSettingsBtn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.generateCodesTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _duration,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.durationLabel, border: const OutlineInputBorder()),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: [
                      DropdownMenuItem(value: 1, child: Text(AppLocalizations.of(context)!.month1Label)),
                      DropdownMenuItem(value: 3, child: Text(AppLocalizations.of(context)!.months3Label)),
                      DropdownMenuItem(value: 6, child: Text(AppLocalizations.of(context)!.months6Label)),
                      DropdownMenuItem(value: 12, child: Text(AppLocalizations.of(context)!.yearLabel)),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _count,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.countLabel, border: const OutlineInputBorder()),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: const [1, 5, 10, 20, 50]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) => setState(() => _count = v ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesOptional, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
              label: _generating ? const SizedBox.shrink() : Text(AppLocalizations.of(context)!.generateBtn),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: تسمية مدّة الكود مترجمة (بدل getter عربي على النموذج).
  String _durationText(AppLocalizations l10n, ActivationCodeModel c) {
    if (c.durationMonths == 1) return l10n.oneMonthLabel;
    if (c.durationMonths == 12) return l10n.yearLabel;
    return l10n.monthsCountX(c.durationMonths);
  }

  String _statusText(AppLocalizations l10n, ActivationCodeModel c) {
    if (c.isUsed) return l10n.codeUsed;
    if (c.isLocked) return l10n.codeLocked;
    return l10n.codeAvailable;
  }

  Widget _codeTile(ActivationCodeModel c) {
    final repo = context.read<SubscriptionRepository>();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        title: Text(c.code,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1)),
        subtitle: Text(
          '${_durationText(l10n, c)} • ${_statusText(l10n, c)}'
          '${c.isUsed && c.usedByName != null ? ' • ${c.usedByName}' : ''}'
          '${c.notes != null && c.notes!.isNotEmpty ? '\n${c.notes}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: c.notes != null && c.notes!.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!c.isUsed)
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: AppLocalizations.of(context)!.copyTooltip,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: c.code));
                  if (mounted) ToobaSnackBar.info(context, AppLocalizations.of(context)!.codeCopied);
                },
              ),
            if (c.isLocked)
              IconButton(
                icon: const Icon(Icons.lock_open, size: 20, color: Colors.orange),
                tooltip: AppLocalizations.of(context)!.unlockTooltip,
                onPressed: () => repo.unlockCode(c.code),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              tooltip: AppLocalizations.of(context)!.delete,
              onPressed: () => repo.deleteCode(c.code),
            ),
          ],
        ),
      ),
    );
  }
}
