import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../app/theme/app_colors.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/functions_service.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.activateWithCode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.enterActivationCodePrompt),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.activationCodeHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(AppLocalizations.of(context)!.activateBtn)),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await FunctionsService()
          .redeemActivationCode(code.trim().toUpperCase());
      await auth.refreshUser();
      if (!mounted) return;
      final months = r['durationMonths'];
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          AppLocalizations.of(context)!.subscriptionActivatedXMonths(months != null ? ' (+$months شهر)' : '')));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          ToobaSnackBar.buildError(e.message ?? AppLocalizations.of(context)!.failedToActivate));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToActivate));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _contactWhatsapp() async {
    if (_whatsapp.isEmpty) return;
    final num = _whatsapp.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$num'
        '?text=${Uri.encodeComponent(AppLocalizations.of(context)!.whatsappActivationMessage)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToOpenWhatsapp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AuthCubit>().state;
    final user = st is AuthAuthenticated ? st.user : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mySubscriptionTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: user == null
            ? Center(child: Text(AppLocalizations.of(context)!.loginFirstToProceed))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statusCard(user),
                  const SizedBox(height: 16),
                  _benefitsCard(isDark),
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
                    label: Text(AppLocalizations.of(context)!.activateWithCode),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  if (_whatsapp.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _contactWhatsapp,
                      icon: const Icon(Icons.chat),
                      label: Text(AppLocalizations.of(context)!.contactToGetCode),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
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
        ? (expiry == null ? AppLocalizations.of(context)!.notSubscribed : AppLocalizations.of(context)!.subscriptionExpired, Colors.red,
            Icons.lock_outline)
        : isTrial
            ? (AppLocalizations.of(context)!.freeTrial, Colors.blue, Icons.timelapse)
            : (AppLocalizations.of(context)!.activeSubscriber, Colors.green, Icons.verified);

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
            Text(AppLocalizations.of(context)!.expiresAtDate(DateFormat('d MMM yyyy', 'ar').format(expiry)),
                style: const TextStyle(color: Colors.white)),
            Text(
                days > 0
                    ? AppLocalizations.of(context)!.daysRemaining(days.toString())
                    : AppLocalizations.of(context)!.expiresToday,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _benefitsCard(bool isDark) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.whatDoesSubscriptionUnlock,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _benefit(AppLocalizations.of(context)!.benefitChallengeRequests),
            _benefit(AppLocalizations.of(context)!.benefitOpenChatWithOpponent),
            _benefit(AppLocalizations.of(context)!.benefitParticipateInTournaments),
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
