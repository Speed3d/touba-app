import '../../../core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import '../../../l10n/app_localizations.dart';

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
          title: Text(AppLocalizations.of(context)!.teamChallengesTitle),
          centerTitle: true,
          bottom: TabBar(
            tabs: [Tab(text: AppLocalizations.of(context)!.teamRequestsTab), Tab(text: AppLocalizations.of(context)!.myChallengesTab)],
          ),
        ),
        floatingActionButton: (!_loading && _hasTeam)
            ? FloatingActionButton.extended(
                onPressed: _createChallenge,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.requestChallengeBtn),
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
        if (list.isEmpty) return _empty(AppLocalizations.of(context)!.noOpenChallengeRequests);
        return ListView(
          padding: const EdgeInsets.all(12),
          children: list.map(_openCard).toList(),
        );
      },
    );
  }

  Widget _openCard(ChallengeModel c) {
    final applied = _uid != null && c.applicantCaptainIds.contains(_uid);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          Text(AppLocalizations.of(context)!.tapToViewTeamPage,
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
                label: Text(applied ? AppLocalizations.of(context)!.appliedStatus : AppLocalizations.of(context)!.acceptChallengeBtn),
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
    if (_uid == null) return _empty(AppLocalizations.of(context)!.pleaseLoginToView);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionTitle(AppLocalizations.of(context)!.myRequestsLabel),
        StreamBuilder<List<ChallengeModel>>(
          stream: repo.streamMine(_uid!),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()));
            }
            final list = snap.data!;
            if (list.isEmpty) return _hint(AppLocalizations.of(context)!.noChallengeRequestsSentYet);
            return Column(children: list.map(_mySentCard).toList());
          },
        ),
        const SizedBox(height: 16),
        _sectionTitle(AppLocalizations.of(context)!.appliedToLabel),
        StreamBuilder<List<ChallengeModel>>(
          stream: repo.streamApplied(_uid!),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox.shrink();
            }
            final list = snap.data!;
            if (list.isEmpty) return _hint(AppLocalizations.of(context)!.noChallengeRequestsAppliedYet);
            return Column(children: list.map(_appliedCard).toList());
          },
        ),
      ],
    );
  }

  Widget _mySentCard(ChallengeModel c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.note?.isNotEmpty == true ? c.note! : AppLocalizations.of(context)!.challengeRequestLabel,
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
              _info(Icons.verified, AppLocalizations.of(context)!.opponentLabelX(c.matchedTeamName ?? "—")),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: c.chatId == null
                      ? null
                      : () => _openChat(c.chatId!, c.matchedTeamName ?? AppLocalizations.of(context)!.opponentLabel),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text(AppLocalizations.of(context)!.openChatBtn),
                ),
              ),
            ] else if (c.isOpen) ...[
              Text(AppLocalizations.of(context)!.applicantsLabelX(c.applicants.length),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (c.applicants.isEmpty)
                Text(AppLocalizations.of(context)!.waitingForTeamsToApply,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
              else
                ...c.applicants.map((a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () => _openTeam(a.teamId),
                      leading: _logo(a.logoUrl, 16),
                      title: Text(a.teamName),
                      subtitle: Text(AppLocalizations.of(context)!.tapToViewTeamBeforeAccepting,
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500])),
                      trailing: ElevatedButton(
                        onPressed: () => _accept(c, a),
                        style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        child: Text(AppLocalizations.of(context)!.acceptBtn),
                      ),
                    )),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _createChallenge(editing: c),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(AppLocalizations.of(context)!.editBtn),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _cancel(c),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: Text(AppLocalizations.of(context)!.cancelRequestBtn,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else
              Text(AppLocalizations.of(context)!.requestCancelledStatus,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _appliedCard(ChallengeModel c) {
    final iAmMatched = c.isMatched && c.matchedCaptainId == _uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        ? AppLocalizations.of(context)!.waitingForRequesterSelection
                        : iAmMatched
                            ? AppLocalizations.of(context)!.yourTeamSelected
                            : c.isMatched
                                ? AppLocalizations.of(context)!.anotherTeamSelected
                                : AppLocalizations.of(context)!.requestCancelledStatus,
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
                label: Text(AppLocalizations.of(context)!.chatLabel),
              ),
          ],
        ),
      ),
    );
  }

  // ─── إجراءات ─────────────────────────────────────────────────────────
  Future<void> _apply(ChallengeModel c) async {
    if (!_requireSub(AppLocalizations.of(context)!.agreeToChallengeSub)) return;
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
      if (mounted) ToobaSnackBar.success(context, AppLocalizations.of(context)!.teamAppliedSuccessfully);
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToApply);
    }
  }

  Future<void> _accept(ChallengeModel c, ChallengeApplicant a) async {
    if (!_requireSub(AppLocalizations.of(context)!.acceptChallengeSub)) return;
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
            AppLocalizations.of(context)!.challengeAcceptedBetweenTeams(c.requesterTeamName, a.teamName),
      );
      // 2) قفل الطلب وربط المحادثة (CF يُشعر الفريق الآخر).
      await challengeRepo.matchWith(c.id, a, chatId);
      if (!mounted) return;
      _openChat(chatId, a.teamName);
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToAcceptChallenge));
    }
  }

  Future<void> _cancel(ChallengeModel c) async {
    try {
      await context.read<ChallengeRepository>().cancel(c.id);
      if (mounted) ToobaSnackBar.info(context, AppLocalizations.of(context)!.requestCancelledStatus);
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToCancel);
    }
  }

  void _openChat(String chatId, String title) {
    Navigator.push(
        context, ToobaRoute.to(ChatScreen(chatId: chatId, title: title)));
  }

  Future<void> _createChallenge({ChallengeModel? editing}) async {
    if (!_requireSub(AppLocalizations.of(context)!.requestChallengeSub)) return;
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
                  child: Text(editing == null ? AppLocalizations.of(context)!.friendlyChallengeRequestTitle : AppLocalizations.of(context)!.editRequestTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Center(
                  child: Text(AppLocalizations.of(context)!.onBehalfOfTeam(t.name, t.city),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.noteOptionalHint,
                    border: const OutlineInputBorder()),
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
                    ? AppLocalizations.of(context)!.suggestedDateOptional
                    : DateFormat('EEE d MMM • HH:mm', 'ar').format(date!)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(editing == null ? AppLocalizations.of(context)!.publishRequestBtn : AppLocalizations.of(context)!.saveEditBtn),
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
        if (mounted) ToobaSnackBar.success(context, AppLocalizations.of(context)!.requestUpdatedSuccessfully);
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
        if (mounted) ToobaSnackBar.success(context, AppLocalizations.of(context)!.challengeRequestPublished);
      }
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToSaveRequest);
    }
  }

  // 📝 HINT AR: عند وجود طلب مفتوح — عرض خيار التعديل أو الإلغاء بدل نشر آخر.
  void _showHasOpenDialog(ChallengeModel existing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.youHaveAnOpenRequestTitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
            AppLocalizations.of(context)!.cannotPublishMultipleRequests),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.okBtn)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancel(existing);
            },
            child: Text(AppLocalizations.of(context)!.cancelRequestBtn,
                style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createChallenge(editing: existing);
            },
            child: Text(AppLocalizations.of(context)!.editRequestTitle),
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
      'matched' => (AppLocalizations.of(context)!.acceptedStatus, Colors.green),
      'cancelled' => (AppLocalizations.of(context)!.cancelledStatus, Colors.grey),
      _ => (AppLocalizations.of(context)!.openStatus, Colors.blue),
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
            ? ImageHelper.getProvider(url)
            : null,
        child: (url == null || url.isEmpty)
            ? Icon(Icons.shield, size: radius, color: Colors.grey.shade400)
            : null,
      );
}
