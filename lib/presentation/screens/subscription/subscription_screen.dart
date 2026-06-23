import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/functions_service.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: شاشة «اشتراكي» (للكابتن — المرحلة 8). تعرض حالة الاشتراك/التجربة
/// والانتهاء، وتتيح التفعيل بكود (عبر CF) والتواصل مع الأدمن (واتساب). عند الفتح
/// تمنح التجربة المجانية تلقائياً إن لم يكن للكابتن اشتراك بعد (CF idempotent).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _busy = false;
  String _whatsapp = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthCubit>();
    final subRepo = context.read<SubscriptionRepository>();
    try {
      final s = await subRepo.getSettings();
      if (mounted) setState(() => _whatsapp = s.whatsapp);
    } catch (_) {}
    // منح التجربة المجانية إن لزم (idempotent خادمياً).
    final st = auth.state;
    final user = st is AuthAuthenticated ? st.user : null;
    if (user != null && user.isCaptain && user.subscriptionExpiresAt == null) {
      try {
        final r = await FunctionsService().startTrialIfEligible();
        if (r['granted'] == true && mounted) {
          await auth.refreshUser();
        }
      } catch (_) {}
    }
  }

  Future<void> _redeem() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthCubit>();
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفعيل بكود'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل كود التفعيل الذي حصلت عليه من الإدارة:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'TBA-XXXX-XXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('تفعيل')),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await FunctionsService()
          .redeemActivationCode(code.trim().toUpperCase());
      await auth.refreshUser();
      final months = r['durationMonths'];
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          'تم تفعيل اشتراكك 🎉${months != null ? ' (+$months شهر)' : ''}'));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
          ToobaSnackBar.buildError(e.message ?? 'تعذّر التفعيل'));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر التفعيل'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _contactWhatsapp() async {
    if (_whatsapp.isEmpty) return;
    final num = _whatsapp.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$num'
        '?text=${Uri.encodeComponent('مرحباً، أريد تفعيل اشتراك طوبة')}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر فتح واتساب');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AuthCubit>().state;
    final user = st is AuthAuthenticated ? st.user : null;
    return Scaffold(
      appBar: AppBar(title: const Text('اشتراكي'), centerTitle: true),
      body: user == null
          ? const Center(child: Text('سجّل الدخول'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statusCard(user),
                const SizedBox(height: 16),
                _benefitsCard(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _redeem,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.vpn_key),
                  label: const Text('تفعيل بكود'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                if (_whatsapp.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _contactWhatsapp,
                    icon: const Icon(Icons.chat),
                    label: const Text('تواصل للحصول على كود'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _statusCard(UserModel user) {
    final active = user.isSubscriptionActive;
    final isTrial = user.subscriptionStatus == 'free_trial';
    final expiry = user.subscriptionExpiresAt;
    final days =
        expiry == null ? 0 : expiry.difference(DateTime.now()).inDays;

    final (label, color, icon) = !active
        ? (expiry == null ? 'غير مشترك' : 'انتهى الاشتراك', Colors.red,
            Icons.lock_outline)
        : isTrial
            ? ('تجربة مجانية', Colors.blue, Icons.timelapse)
            : ('مشترك فعّال', Colors.green, Icons.verified);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 44),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          if (active && expiry != null) ...[
            const SizedBox(height: 6),
            Text('ينتهي: ${DateFormat('d MMM yyyy', 'ar').format(expiry)}',
                style: const TextStyle(color: Colors.white)),
            Text(
                days > 0
                    ? 'متبقّي $days يوم'
                    : 'ينتهي اليوم',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ماذا يفتح الاشتراك؟',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _benefit('طلب تحدّيات الفرق والموافقة عليها'),
            _benefit('فتح محادثة مع كابتن الفريق المنافس'),
            _benefit('المشاركة في البطولات (حسب نوع البطولة)'),
          ],
        ),
      ),
    );
  }

  Widget _benefit(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
