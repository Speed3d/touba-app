import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../cubits/team/team_cubit.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';
import '../chat/chat_screen.dart';
import '../teams/team_details_screen.dart';
import '../subscription/subscription_locked_sheet.dart';

/// 📝 HINT AR: تحدّيات الفرق الودّية (المرحلة 7). تبويبان: «طلبات الفرق» (المفتوحة)
/// و«تحدياتي» (طلباتي + ما تقدّمت إليه). القبول يفتح محادثة بين الكابتنين.
/// ⚠️ القفل بالاشتراك يُضاف في المرحلة 8 (انظر [_canChallenge]).
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  TeamModel? _myTeam;
  UserModel? _user;
  String? _uid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = context.read<AuthCubit>().state;
    if (st is AuthAuthenticated) {
      _user = st.user;
      _uid = st.user.id;
    }
    if (_uid != null) {
      try {
        _myTeam = await context.read<TeamRepository>().getTeamByCaptain(_uid!);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  // 📝 HINT AR: التصفّح مجاني؛ امتلاك فريق يُظهر أزرار الفعل (المرحلة 7).
  bool get _hasTeam => _myTeam != null;

  // 📝 HINT AR: قفل المرحلة 8 — الطلب والقبول يتطلّبان اشتراكاً فعّالاً.
  bool get _isSubscribed => _user?.isSubscriptionActive ?? false;

  /// يتحقّق من الاشتراك قبل فعل مقفول؛ يعرض ورقة القفل ويُعيد false إن لزم.
  bool _requireSub(String feature) {
    if (_isSubscribed) return true;
    SubscriptionLockedSheet.show(context, feature: feature);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحدّيات الفرق'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [Tab(text: 'طلبات الفرق'), Tab(text: 'تحدياتي')],
          ),
        ),
        floatingActionButton: (!_loading && _hasTeam)
            ? FloatingActionButton.extended(
                onPressed: _createChallenge,
                icon: const Icon(Icons.add),
                label: const Text('أطلب تحدّياً'),
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [_openTab(), _myTab()],
              ),
      ),
    );
  }

  // ─── تبويب «طلبات الفرق» ─────────────────────────────────────────────
  Widget _openTab() {
    return StreamBuilder<List<ChallengeModel>>(
      stream: context.read<ChallengeRepository>().streamOpen(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // نستثني طلبي ونعرض المفتوحة فقط.
        final list =
            snap.data!.where((c) => c.requesterCaptainId != _uid).toList();
        if (list.isEmpty) return _empty('لا توجد طلبات تحدٍّ مفتوحة حالياً');
        return ListView(
          padding: const EdgeInsets.all(12),
          children: list.map(_openCard).toList(),
        );
      },
    );
  }

  Widget _openCard(ChallengeModel c) {
    final applied = _uid != null && c.applicantCaptainIds.contains(_uid);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openTeam(c.requesterTeamId),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    _logo(c.requesterLogo, 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.requesterTeamName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('اضغط لعرض صفحة الفريق',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    _cityChip(c.city),
                    const Icon(Icons.chevron_left, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (c.note != null && c.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(c.note!, style: TextStyle(color: Colors.grey[700])),
            ],
            if (c.matchDate != null) ...[
              const SizedBox(height: 6),
              _info(Icons.event, DateFormat('EEE d MMM • HH:mm', 'ar')
                  .format(c.matchDate!)),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (applied || !_hasTeam) ? null : () => _apply(c),
                icon: Icon(applied ? Icons.check : Icons.sports_soccer,
                    size: 18),
                label: Text(applied ? 'تم التقديم' : 'أوافق على التحدي'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── تبويب «تحدياتي» ─────────────────────────────────────────────────
  Widget _myTab() {
    final repo = context.read<ChallengeRepository>();
    if (_uid == null) return _empty('سجّل الدخول');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionTitle('طلباتي'),
        StreamBuilder<List<ChallengeModel>>(
          stream: repo.streamMine(_uid!),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()));
            }
            final list = snap.data!;
            if (list.isEmpty) return _hint('لم تُرسل أي طلب تحدٍّ بعد');
            return Column(children: list.map(_mySentCard).toList());
          },
        ),
        const SizedBox(height: 16),
        _sectionTitle('تقدّمت إليها'),
        StreamBuilder<List<ChallengeModel>>(
          stream: repo.streamApplied(_uid!),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox.shrink();
            }
            final list = snap.data!;
            if (list.isEmpty) return _hint('لم تتقدّم لأي تحدٍّ بعد');
            return Column(children: list.map(_appliedCard).toList());
          },
        ),
      ],
    );
  }

  Widget _mySentCard(ChallengeModel c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.note?.isNotEmpty == true ? c.note! : 'طلب تحدٍّ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _statusChip(c.status),
              ],
            ),
            if (c.matchDate != null) ...[
              const SizedBox(height: 6),
              _info(Icons.event,
                  DateFormat('EEE d MMM • HH:mm', 'ar').format(c.matchDate!)),
            ],
            const Divider(height: 18),
            if (c.isMatched) ...[
              _info(Icons.verified, 'الخصم: ${c.matchedTeamName ?? "—"}'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: c.chatId == null
                      ? null
                      : () => _openChat(c.chatId!, c.matchedTeamName ?? 'الخصم'),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('فتح المحادثة'),
                ),
              ),
            ] else if (c.isOpen) ...[
              Text('المتقدّمون (${c.applicants.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (c.applicants.isEmpty)
                Text('بانتظار تقديم الفرق…',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
              else
                ...c.applicants.map((a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () => _openTeam(a.teamId),
                      leading: _logo(a.logoUrl, 16),
                      title: Text(a.teamName),
                      subtitle: Text('اضغط لعرض الفريق قبل القبول',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500])),
                      trailing: ElevatedButton(
                        onPressed: () => _accept(c, a),
                        style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        child: const Text('قبول'),
                      ),
                    )),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _createChallenge(editing: c),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('تعديل'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _cancel(c),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('إلغاء الطلب',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else
              Text('أُلغي الطلب',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _appliedCard(ChallengeModel c) {
    final iAmMatched = c.isMatched && c.matchedCaptainId == _uid;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _logo(c.requesterLogo, 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.requesterTeamName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    c.isOpen
                        ? 'بانتظار اختيار صاحب الطلب'
                        : iAmMatched
                            ? 'تم اختيار فريقك! 🎉'
                            : c.isMatched
                                ? 'اختار فريقاً آخر'
                                : 'أُلغي الطلب',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (iAmMatched && c.chatId != null)
              OutlinedButton.icon(
                onPressed: () =>
                    _openChat(c.chatId!, c.requesterTeamName),
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('محادثة'),
              ),
          ],
        ),
      ),
    );
  }

  // ─── إجراءات ─────────────────────────────────────────────────────────
  Future<void> _apply(ChallengeModel c) async {
    if (!_requireSub('الموافقة على التحدّي')) return;
    final t = _myTeam!;
    try {
      await context.read<ChallengeRepository>().apply(
            c.id,
            ChallengeApplicant(
                teamId: t.id,
                teamName: t.name,
                captainId: _uid!,
                logoUrl: t.logoUrl),
          );
      if (mounted) ToobaSnackBar.success(context, 'تم تقديم فريقك للتحدّي');
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر التقديم');
    }
  }

  Future<void> _accept(ChallengeModel c, ChallengeApplicant a) async {
    if (!_requireSub('قبول التحدّي')) return;
    final messenger = ScaffoldMessenger.of(context);
    final chatRepo = context.read<ChatRepository>();
    final challengeRepo = context.read<ChallengeRepository>();
    try {
      // 1) فتح محادثة بين الكابتنين (أسماء الفرق للعرض).
      final chatId = await chatRepo.createOrGetChat(
        myUid: _uid!,
        myName: c.requesterTeamName,
        myPhoto: c.requesterLogo,
        otherUid: a.captainId,
        otherName: a.teamName,
        otherPhoto: a.logoUrl,
        challengeId: c.id,
        welcome:
            'تم قبول التحدّي بين «${c.requesterTeamName}» و«${a.teamName}» 👋 اتفقوا على الموعد والمكان.',
      );
      // 2) قفل الطلب وربط المحادثة (CF يُشعر الفريق الآخر).
      await challengeRepo.matchWith(c.id, a, chatId);
      if (!mounted) return;
      _openChat(chatId, a.teamName);
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر قبول التحدّي'));
    }
  }

  Future<void> _cancel(ChallengeModel c) async {
    try {
      await context.read<ChallengeRepository>().cancel(c.id);
      if (mounted) ToobaSnackBar.info(context, 'أُلغي الطلب');
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر الإلغاء');
    }
  }

  void _openChat(String chatId, String title) {
    Navigator.push(
        context, ToobaRoute.to(ChatScreen(chatId: chatId, title: title)));
  }

  Future<void> _createChallenge({ChallengeModel? editing}) async {
    if (!_requireSub('طلب تحدٍّ')) return;
    final t = _myTeam!;
    final challengeRepo = context.read<ChallengeRepository>();
    // 📝 HINT AR: طلب واحد مفتوح فقط لكل كابتن (منع التلاعب) — عدّله أو ألغِه.
    if (editing == null) {
      final existing = await challengeRepo.getMyOpenChallenge(_uid!);
      if (existing != null) {
        if (!mounted) return;
        _showHasOpenDialog(existing);
        return;
      }
    }
    final noteCtrl = TextEditingController(text: editing?.note ?? '');
    DateTime? date = editing?.matchDate;
    if (!mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Text(editing == null ? 'طلب تحدٍّ ودّي' : 'تعديل الطلب',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Center(
                  child: Text('باسم فريق «${t.name}» • ${t.city}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري) — المكان/التوقيت المقترح',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 1),
                  );
                  if (d == null || !ctx.mounted) return;
                  final tm = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 18, minute: 0));
                  if (tm == null) return;
                  date = DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
                  setS(() {});
                },
                icon: const Icon(Icons.event, size: 18),
                label: Text(date == null
                    ? 'موعد مقترح (اختياري)'
                    : DateFormat('EEE d MMM • HH:mm', 'ar').format(date!)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(editing == null ? 'نشر الطلب' : 'حفظ التعديل'),
              ),
            ],
          ),
        ),
      ),
    );
    if (created != true) return;
    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
    try {
      if (editing != null) {
        await challengeRepo.updateChallenge(editing.id,
            note: note, matchDate: date);
        if (mounted) ToobaSnackBar.success(context, 'تم تحديث الطلب');
      } else {
        final c = ChallengeModel(
          id: const Uuid().v4(),
          requesterTeamId: t.id,
          requesterTeamName: t.name,
          requesterCaptainId: _uid!,
          requesterLogo: t.logoUrl,
          city: t.city,
          note: note,
          matchDate: date,
          status: 'open',
        );
        await challengeRepo.createChallenge(c);
        if (mounted) ToobaSnackBar.success(context, 'تم نشر طلب التحدّي');
      }
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر حفظ الطلب');
    }
  }

  // 📝 HINT AR: عند وجود طلب مفتوح — عرض خيار التعديل أو الإلغاء بدل نشر آخر.
  void _showHasOpenDialog(ChallengeModel existing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لديك طلب مفتوح'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
            'لا يمكن نشر أكثر من طلب تحدٍّ مفتوح في آنٍ واحد. عدّل طلبك الحالي أو ألغِه أولاً.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancel(existing);
            },
            child: const Text('إلغاء الطلب',
                style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createChallenge(editing: existing);
            },
            child: const Text('تعديل الطلب'),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: فتح صفحة فريق (لمشاهدة ملف صاحب الطلب/المتقدّم قبل الموافقة).
  void _openTeam(String teamId) {
    Navigator.push(
      context,
      ToobaRoute.to(BlocProvider(
        create: (ctx) => TeamCubit(
          ctx.read<TeamRepository>(),
          ctx.read<PlayerRepository>(),
        ),
        child: TeamDetailsScreen(teamId: teamId),
      )),
    );
  }

  // ─── عناصر مساعدة ────────────────────────────────────────────────────
  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
        ),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _info(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
        ],
      );

  Widget _cityChip(String city) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Text(city,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'matched' => ('تم القبول', Colors.green),
      'cancelled' => ('ملغى', Colors.grey),
      _ => ('مفتوح', Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _logo(String? url, double radius) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (url != null && url.isNotEmpty)
            ? CachedNetworkImageProvider(url)
            : null,
        child: (url == null || url.isEmpty)
            ? Icon(Icons.shield, size: radius, color: Colors.grey.shade400)
            : null,
      );
}
