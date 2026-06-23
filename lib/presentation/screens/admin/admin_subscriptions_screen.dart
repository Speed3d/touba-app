import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/activation_code_model.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

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
      if (mounted) ToobaSnackBar.success(context, 'تم حفظ الإعدادات');
    } catch (_) {
      if (mounted) {
        ToobaSnackBar.error(context, 'تعذّر الحفظ (يتطلّب صلاحية مدير أعلى)');
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
        ToobaSnackBar.success(context, 'تم توليد ${codes.length} كود');
      }
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر التوليد');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SubscriptionRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('أكواد التفعيل'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsCard(),
          const SizedBox(height: 16),
          _generateCard(),
          const SizedBox(height: 20),
          const Text('الأكواد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  child: Text('لا توجد أكواد بعد',
                      style: TextStyle(color: Colors.grey[600])),
                );
              }
              return Column(children: codes.map(_codeTile).toList());
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('الإعدادات',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _trialCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'مدة التجربة المجانية (أيام)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _whatsappCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'واتساب التفعيل (مثال: 9647xx)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _savingSettings ? null : _saveSettings,
              child: _savingSettings
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('توليد أكواد',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _duration,
                    decoration: const InputDecoration(
                        labelText: 'المدة', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('شهر')),
                      DropdownMenuItem(value: 3, child: Text('3 أشهر')),
                      DropdownMenuItem(value: 6, child: Text('6 أشهر')),
                      DropdownMenuItem(value: 12, child: Text('سنة')),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _count,
                    decoration: const InputDecoration(
                        labelText: 'العدد', border: OutlineInputBorder()),
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
              decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)', border: OutlineInputBorder()),
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
              label: const Text('توليد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeTile(ActivationCodeModel c) {
    final repo = context.read<SubscriptionRepository>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(c.code,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1)),
        subtitle: Text(
          '${c.durationLabel} • ${c.statusText}'
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
                tooltip: 'نسخ',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: c.code));
                  if (mounted) ToobaSnackBar.info(context, 'تم نسخ الكود');
                },
              ),
            if (c.isLocked)
              IconButton(
                icon: const Icon(Icons.lock_open, size: 20, color: Colors.orange),
                tooltip: 'فكّ القفل',
                onPressed: () => repo.unlockCode(c.code),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              tooltip: 'حذف',
              onPressed: () => repo.deleteCode(c.code),
            ),
          ],
        ),
      ),
    );
  }
}
