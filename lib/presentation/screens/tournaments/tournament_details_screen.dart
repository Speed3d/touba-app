import '../../../core/utils/image_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/tournament_lineup_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/tournament_lineup_repository.dart';
import '../../../data/services/functions_service.dart';
import 'enter_result_screen.dart';
import 'tournament_rules_editor.dart';
import 'tournament_lineup_screen.dart';
import 'tournament_lineups_review_screen.dart';
import '../matches/match_detail_screen.dart';
import '../../widgets/core/live_match_timer.dart';
import '../../widgets/core/standings_view.dart';
import '../../widgets/core/bracket_view.dart';
import '../../../data/services/fixtures_pdf_service.dart';
import '../../../core/utils/formations.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: تفاصيل البطولة — جدول الترتيب الحيّ + المباريات + إدخال النتيجة
/// (للمنظّم/الأدمن). إدخال النتيجة يُشغّل المحرّك الذرّي فيُحدّث الترتيب.
class TournamentDetailsScreen extends StatelessWidget {
  final String tournamentId;
  const TournamentDetailsScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البطولة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'تفاصيل'),
            Tab(text: 'شروط وقوانين'),
            Tab(text: 'الفرق المشاركة'),
          ],
        ),
      ),
      body: BlocConsumer<TournamentCubit, TournamentState>(
        listener: (context, state) {
          if (state is TournamentActionSuccess) {
            ToobaSnackBar.success(context, state.message);
          } else if (state is TournamentError) {
            ToobaSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is TournamentDetailsLoaded) {
            final t = state.tournament;
            final canManage = currentUser != null &&
                (currentUser.isAdmin || t.organizerUid == currentUser.id);
            return TabBarView(
              children: [
                // ── تبويب «تفاصيل» ──
                RefreshIndicator(
              onRefresh: () =>
                  context.read<TournamentCubit>().fetchDetails(tournamentId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(t.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Center(child: Text('${t.city} • ${_typeLabel(t.type)}')),
                  // 📝 HINT AR: بطولة باشتراك (المرحلة 8) — الدخول يُدار من الأدمن.
                  if (!t.isFree) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium,
                                size: 15, color: Colors.amber.shade800),
                            const SizedBox(width: 4),
                            Text(
                              t.entryInfo?.isNotEmpty == true
                                  ? 'بطولة باشتراك • ${t.entryInfo}'
                                  : 'بطولة باشتراك',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // 📝 HINT AR: مراجعة تشكيلات الفرق (للمنظّم) — بند 8.
                  if (canManage) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          ToobaRoute.to(TournamentLineupsReviewScreen(
                              tournamentId: t.id, canManage: true)),
                        ),
                        icon: const Icon(Icons.fact_check, size: 16),
                        label: const Text('مراجعة تشكيلات الفرق'),
                      ),
                    ),
                  ],
                  // 📝 HINT AR: تشكيلتي في البطولة (لكابتن فريق مشارك) — بند 8.
                  // تختفي بعد انتهاء البطولة (منع تغيير حقوق اللاعبين بأثر رجعي).
                  if (t.status != 'finished' &&
                      _myParticipatingTeam(state, currentUser) != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final team =
                              _myParticipatingTeam(state, currentUser)!;
                          Navigator.push(
                            context,
                            ToobaRoute.to(TournamentLineupScreen(
                              tournamentId: t.id,
                              tournamentName: t.name,
                              playerFormat: t.playerFormat,
                              teamId: team.id,
                              teamName: team.name,
                            )),
                          );
                        },
                        icon: const Icon(Icons.groups, size: 18),
                        label: const Text('تشكيلتي في البطولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  // 📝 HINT AR: تقديم طلب تحكيم — لأي مستخدم ليس منظّم/أدمن وليس
                  // حكماً أصلاً (الحكم يظهر تلقائياً في قائمة الحكّام للمنظّم).
                  if (currentUser != null && !canManage &&
                      !currentUser.isReferee &&
                      t.status != 'finished') ...[
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyAsReferee(context, t, currentUser),
                        icon: const Icon(Icons.sports, size: 16),
                        label: const Text('تقديم طلب تحكيم لهذه البطولة'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (t.status == 'finished' && t.winnerTeamName != null) ...[
                    _championBanner(context, t, state),
                    const SizedBox(height: 16),
                  ],
                  _standingsOrBracket(context, state),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('المباريات',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // 📝 HINT AR: تصدير جدول البطولة PDF (للمنظّم) — بند 6.
                      if (canManage && state.matches.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _exportSchedulePdf(context, state),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('تصدير PDF',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._matchTiles(context, state, canManage),
                  const SizedBox(height: 24),
                ],
              ),
                ),
                // ── تبويب «شروط وقوانين» ──
                _rulesTab(context, state, canManage),
                // ── تبويب «الفرق المشاركة» ──
                _teamsTab(context, state, canManage),
              ],
            );
          }
          if (state is TournamentError) {
            return Center(child: Text('خطأ: ${state.message}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      ),
    );
  }

  // 📝 HINT AR: تبويب «شروط وقوانين» — بانر إعلانات متحرك + نصّ الشروط/القوانين
  // + لوكوات الداعمين بحجم كبير. المنظّم/الأدمن يحرّرها عبر زر «تعديل».
  Widget _rulesTab(
      BuildContext context, TournamentDetailsLoaded state, bool canManage) {
    final t = state.tournament;
    final hasRules = t.rules != null && t.rules!.trim().isNotEmpty;
    final hasSponsors = t.sponsors.isNotEmpty;
    final hasBanners = t.adBanners.isNotEmpty;
    final empty = !hasRules && !hasSponsors && !hasBanners;

    return RefreshIndicator(
      onRefresh: () =>
          context.read<TournamentCubit>().fetchDetails(tournamentId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (canManage) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _editRules(context, t),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل الشروط والداعمين'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasBanners) ...[
            _AdBannerSlider(images: t.adBanners),
            const SizedBox(height: 20),
          ],
          if (hasRules) ...[
            _sectionTitle(context, 'الشروط والقوانين', Icons.gavel),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(t.rules!, style: const TextStyle(height: 1.6)),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (hasSponsors) ...[
            _sectionTitle(context, 'الداعمون', Icons.handshake),
            const SizedBox(height: 12),
            _sponsorsView(t.sponsors),
            const SizedBox(height: 20),
          ],
          if (empty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.gavel, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      canManage
                          ? 'لا توجد شروط أو داعمون بعد — اضغط «تعديل» للإضافة'
                          : 'لا توجد شروط أو داعمون لهذه البطولة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 📝 HINT AR: لوكوات الداعمين بحجم كبير (دوائر) + الاسم تحت كل لوغو.
  Widget _sponsorsView(List<Sponsor> sponsors) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: sponsors
          .map((s) => SizedBox(
                width: 100,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: s.logoUrl.isNotEmpty
                          ? ImageHelper.getProvider(s.logoUrl)
                          : null,
                      child: s.logoUrl.isEmpty
                          ? const Icon(Icons.handshake, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // 📝 HINT AR: يفتح محرّر الشروط والداعمين (للمنظّم/الأدمن) ثم يعيد جلب التفاصيل.
  void _editRules(BuildContext context, TournamentModel t) {
    final cubit = context.read<TournamentCubit>();
    final repo = context.read<TournamentRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TournamentRulesEditor(
        tournament: t,
        repo: repo,
        onSaved: () => cubit.fetchDetails(tournamentId),
      ),
    );
  }

  // 📝 HINT AR: تبويب «الفرق المشاركة» (بند 2) — كل الفرق مع حالة تشكيلتها (لم
  // يُرسل / تم الإرسال / تم التحقق / مرفوضة). الضغط على فريق أرسل يفتح المراجعة
  // (لاعبوها قابلون للنقر لفتح صفحاتهم)؛ وفريق لم يُرسل يفتح نافذة تذكير (للمنظّم).
  Widget _teamsTab(
      BuildContext context, TournamentDetailsLoaded state, bool canManage) {
    final t = state.tournament;
    return FutureBuilder<List<TournamentLineupModel>>(
      future: context
          .read<TournamentLineupRepository>()
          .getLineupsForTournament(t.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final byTeam = {
          for (final l in snap.data ?? <TournamentLineupModel>[]) l.teamId: l
        };
        return RefreshIndicator(
          onRefresh: () =>
              context.read<TournamentCubit>().fetchDetails(tournamentId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('حالة تشكيلات الفرق (${t.teamIds.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  canManage
                      ? 'اضغط فريقاً أرسل لمراجعة تشكيلته، أو فريقاً لم يُرسل لتذكيره.'
                      : 'اضغط فريقاً أرسل لعرض تشكيلته.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
              if (t.teamIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('لا فرق مشاركة',
                      style: TextStyle(color: Colors.grey[600])),
                )
              else
                ...t.teamIds.map((id) => _teamStatusCard(
                    context, state, id, byTeam[id], canManage)),
            ],
          ),
        );
      },
    );
  }

  Widget _teamStatusCard(BuildContext context, TournamentDetailsLoaded state,
      String teamId, TournamentLineupModel? lineup, bool canManage) {
    final team = state.teamsById[teamId];
    final name = team?.name ?? '—';
    Color color;
    String label;
    IconData icon;
    if (lineup == null) {
      color = Colors.orange;
      label = 'لم يُرسل';
      icon = Icons.hourglass_empty;
    } else if (lineup.isApproved) {
      color = Colors.green;
      label = 'تم التحقق';
      icon = Icons.verified;
    } else if (lineup.isRejected) {
      color = Colors.red;
      label = 'مرفوضة';
      icon = Icons.cancel;
    } else {
      color = Colors.blue;
      label = 'تم الإرسال';
      icon = Icons.send;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _teamLogo(team?.logoUrl, 18),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Icon(
            lineup == null && !canManage
                ? Icons.lock_clock
                : Icons.chevron_left,
            color: Colors.grey[400]),
        onTap: () {
          if (lineup != null) {
            Navigator.push(
              context,
              ToobaRoute.to(TournamentLineupsReviewScreen(
                  tournamentId: state.tournament.id, canManage: canManage)),
            );
          } else if (canManage) {
            _remindCaptain(context, state.tournament.id, teamId, name);
          } else {
            ToobaSnackBar.info(context, 'لم يُرسِل الكابتن تشكيلته بعد');
          }
        },
      ),
    );
  }

  // 📝 HINT AR: تذكير كابتن لم يُرسل تشكيلته (عبر CF remindLineup) مع رسالة اختيارية.
  Future<void> _remindCaptain(BuildContext context, String tournamentId,
      String teamId, String teamName) async {
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تذكير فريق $teamName'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيصل تنبيه لكابتن الفريق بضرورة إرسال التشكيلة. إن لم تُرسَل '
              'يمكنك إقصاء الفريق أو إدخال خسارة 3-0 يدوياً.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'رسالة مخصّصة (اختياري)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال التذكير')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FunctionsService()
          .remindLineup(tournamentId, teamId, ctrl.text.trim());
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess('أُرسل التذكير لكابتن $teamName'));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر إرسال التذكير'));
    }
  }

  // 📝 HINT AR: بانر تتويج البطل عند انتهاء البطولة — كأس/شعار البطل + الجوائز
  // + الراعي (يضبطها الأدمن من «إدارة البطولات»).
  Widget _championBanner(
      BuildContext context, TournamentModel t, TournamentDetailsLoaded state) {
    final winnerTeam = state.teamsById[t.winnerTeamId];
    final cupOrLogo = (t.cupImageUrl != null && t.cupImageUrl!.isNotEmpty)
        ? CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            backgroundImage: ImageHelper.getProvider(t.cupImageUrl!),
          )
        : const Icon(Icons.emoji_events, color: Colors.white, size: 48);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          cupOrLogo,
          const SizedBox(height: 8),
          const Text('بطل البطولة',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (winnerTeam?.logoUrl != null) ...[
                _teamLogo(winnerTeam!.logoUrl, 14),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(t.winnerTeamName ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
          if (t.prizes != null && t.prizes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _championInfo(Icons.card_giftcard, 'الجوائز: ${t.prizes}'),
          ],
          if (t.sponsorName != null && t.sponsorName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _championInfo(Icons.handshake, 'الراعي: ${t.sponsorName}'),
          ],
        ],
      ),
    );
  }

  Widget _championInfo(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'knockout':
        return 'خروج المغلوب';
      case 'groups':
        return 'مجموعات';
      default:
        return 'دوري';
    }
  }

  // 📝 HINT AR: الترتيب (دوري/مجموعات) و/أو شجرة الإقصائي (الوجبة 7). الدوري:
  // جدول واحد. المجموعات: جدول لكل مجموعة + الشجرة إن وُلِّدت. الإقصائي: الشجرة فقط.
  Widget _standingsOrBracket(
      BuildContext context, TournamentDetailsLoaded state) {
    final t = state.tournament;
    final knockoutMatches =
        state.matches.where((m) => m.stage == 'knockout').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.type != 'knockout')
          StandingsView(
              standings: t.standings, teamsById: state.teamsById),
        if (knockoutMatches.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle(context, 'المرحلة الإقصائية', Icons.account_tree),
          const SizedBox(height: 8),
          BracketView(
            matches: knockoutMatches,
            onMatchTap: (m) => Navigator.push(
                context, ToobaRoute.to(MatchDetailScreen(match: m))),
          ),
        ],
        // 📝 HINT AR: زر توليد الإقصائي يدوياً (للطوارئ) — للمنظّم في بطولة مجموعات
        // اكتملت ولم يُولَّد إقصائيها تلقائياً.
        if (t.type == 'groups' &&
            !t.bracketGenerated &&
            (currentUserCanManage(context, t)))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => _generateKnockout(context, t.id),
              icon: const Icon(Icons.account_tree, size: 16),
              label: const Text('توليد المرحلة الإقصائية'),
            ),
          ),
      ],
    );
  }

  bool currentUserCanManage(BuildContext context, TournamentModel t) {
    final auth = context.read<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    return user != null && (user.isAdmin || t.organizerUid == user.id);
  }

  Future<void> _generateKnockout(
      BuildContext context, String tournamentId) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<TournamentCubit>();
    messenger.showSnackBar(ToobaSnackBar.buildInfo('جارٍ توليد المرحلة...'));
    try {
      await FunctionsService().generateKnockout(tournamentId);
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess('تم توليد المرحلة الإقصائية'));
      await cubit.fetchDetails(tournamentId);
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError(
          'تعذّر التوليد — تأكّد من اكتمال مباريات المجموعات'));
    }
  }

  List<Widget> _matchTiles(
      BuildContext context, TournamentDetailsLoaded state, bool canManage) {
    if (state.matches.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('لا توجد مباريات', style: TextStyle(color: Colors.grey[600])),
        )
      ];
    }

    // 📝 HINT AR: تجميع المباريات بالجولة للعرض المنظّم.
    final byRound = <int, List<MatchModel>>{};
    for (final m in state.matches) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    final rounds = byRound.keys.toList()..sort();

    final tiles = <Widget>[];
    for (final round in rounds) {
      tiles.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'الجولة $round',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
            ),
          ),
        ),
      );
      for (final m in byRound[round]!) {
        tiles.add(_matchTile(context, m, canManage, state));
      }
    }
    return tiles;
  }

  Widget _matchTile(BuildContext context, MatchModel m, bool canManage,
      TournamentDetailsLoaded state) {
    final theme = Theme.of(context);
    final tournament = state.tournament;
    final finished = m.resultConfirmed;
    final hasDate = m.dateTime != null;
    final isLive = m.status == 'live';
    // 📝 HINT AR: هل المُشاهد كابتن أحد فريقَي هذه المباراة؟ (لتغيير خطته — بند 8)
    final auth = context.read<AuthCubit>().state;
    final uid = auth is AuthAuthenticated ? auth.user.id : null;
    final isHomeCaptain =
        uid != null && state.teamsById[m.homeTeamId]?.captainId == uid;
    final isAwayCaptain =
        uid != null && state.teamsById[m.awayTeamId]?.captainId == uid;
    final isMatchCaptain = isHomeCaptain || isAwayCaptain;
    final dateLabel = hasDate
        ? DateFormat('EEE d MMM • HH:mm', 'ar').format(m.dateTime!)
        : 'موعد غير محدد';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // 📝 HINT AR: تُفتح تفاصيل المباراة لكل الحالات (WS2) — للمنظّم لوحة تحكّم
        // حيّة، وللمشاهد النتيجة اللحظية والمؤقّت.
        onTap: () => Navigator.push(
          context,
          ToobaRoute.to(MatchDetailScreen(match: m)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── صف الموعد + الشارة ──
              Row(
                children: [
                  Icon(
                    finished
                        ? Icons.check_circle_outline
                        : (hasDate
                            ? Icons.calendar_month
                            : Icons.calendar_today_outlined),
                    size: 14,
                    color: finished
                        ? Colors.green
                        : (hasDate
                            ? theme.colorScheme.primary
                            : Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    finished ? 'انتهت' : dateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: finished
                          ? Colors.green
                          : (hasDate
                              ? theme.colorScheme.primary
                              : Colors.grey),
                      fontWeight:
                          hasDate && !finished ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  // ── شارة التقدم ──
                  if (isLive)
                    LiveMatchTimer(
                      startedAt: m.matchStartedAt,
                      currentHalf: m.currentHalf,
                      matchDuration: tournament.matchDuration,
                      halvesCount: tournament.halvesCount,
                      compact: true,
                    )
                  else if (!finished && !hasDate && canManage)
                    _badge('بدون موعد', Colors.orange.shade100,
                        Colors.orange.shade700)
                  else if (!finished &&
                      hasDate &&
                      m.dateTime!.isAfter(DateTime.now()))
                    _badge('قادمة', Colors.blue.shade50, Colors.blue.shade700),
                  if (finished)
                    _badge('${m.homeScore} - ${m.awayScore}',
                        Colors.green.shade50, Colors.green.shade700),
                ],
              ),
              const SizedBox(height: 8),
              // ── صف الفريقين ──
              Row(
                children: [
                  _teamLogo(m.homeTeamLogo, 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      m.homeTeamName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text('ضد',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Expanded(
                    child: Text(
                      m.awayTeamName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _teamLogo(m.awayTeamLogo, 12),
                ],
              ),
              // ── الحكم المعيّن ──
              if (m.refereeName != null && m.refereeName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.sports, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('الحكم: ${m.refereeName}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
              // ── تعيين حكم (للمنظّم، قبل انتهاء المباراة) ──
              if (canManage && !finished) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _pickReferee(context, m),
                    icon: const Icon(Icons.sports, size: 16),
                    label: Text(
                        m.refereeId == null ? 'تعيين حكم' : 'تغيير الحكم',
                        style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ],
              // ── خطة الكابتن لهذه المباراة (بند 8) ──
              if (isMatchCaptain && !canManage && !finished) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMatchFormation(
                        context, m, isHomeCaptain, tournament.playerFormat),
                    icon: const Icon(Icons.dashboard_customize, size: 16),
                    label: Text(
                      (() {
                        final f =
                            isHomeCaptain ? m.homeFormation : m.awayFormation;
                        return (f != null && f.isNotEmpty)
                            ? 'خطة فريقي: $f'
                            : 'تحديد خطة فريقي';
                      })(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ],
              // ── أزرار المنظّم ──
              if (canManage && !finished) ...[
                const SizedBox(height: 8),
                // ── تحكّم المباراة الحيّة ──
                if (!isLive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context
                          .read<TournamentCubit>()
                          .startMatch(m.tournamentId, m.id),
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      label: const Text('بدأ المباراة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                else if (m.currentHalf < tournament.halvesCount)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .read<TournamentCubit>()
                          .startNextHalf(
                              m.tournamentId, m.id, m.currentHalf + 1),
                      icon: const Icon(Icons.fast_forward, size: 18),
                      label: Text('بدأ الشوط ${m.currentHalf + 1}'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // زر تحديد/تعديل الموعد
                    OutlinedButton.icon(
                      onPressed: () =>
                          _pickDateTime(context, m),
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: Text(
                        hasDate ? 'تعديل الموعد' : 'تحديد الموعد',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر إدخال النتيجة
                    ElevatedButton.icon(
                      onPressed: () {
                        final cubit = context.read<TournamentCubit>();
                        Navigator.push(
                          context,
                          ToobaRoute.to(BlocProvider.value(
                            value: cubit,
                            child: EnterResultScreen(
                                match: m,
                                tournamentId: m.tournamentId),
                          )),
                        );
                      },
                      icon: const Icon(Icons.sports_score, size: 16),
                      label: const Text('إدخال النتيجة',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 📝 HINT AR: تقديم طلب تحكيم لهذه البطولة (يستلمه الأدمن).
  Future<void> _applyAsReferee(
      BuildContext context, TournamentModel t, UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<TournamentRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طلب تحكيم'),
        content: Text(
            'هل تريد تقديم طلب للتحكيم في بطولة «${t.name}»؟ سيراجعه الأدمن.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تقديم')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.applyAsReferee(
        userId: user.id,
        userName: user.name,
        userPhone: user.phone,
        tournament: t,
      );
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess('تم إرسال طلب التحكيم للأدمن'));
    } catch (e) {
      messenger.showSnackBar(ToobaSnackBar.buildError(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // 📝 HINT AR: منتقي خطة الكابتن لمباراته (قوالب نظام البطولة) — بند 8.
  void _pickMatchFormation(
      BuildContext context, MatchModel m, bool isHome, int playerFormat) {
    final cubit = context.read<TournamentCubit>();
    final options = kFormationOptions[playerFormat] ??
        [defaultFormationFor(playerFormat)];
    final current = isHome ? m.homeFormation : m.awayFormation;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر خطة فريقك لهذه المباراة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('الصيغة: حارس-دفاع-وسط-هجوم',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in options)
                    ChoiceChip(
                      label: Text(f),
                      selected: current == f,
                      onSelected: (_) {
                        Navigator.pop(ctx);
                        cubit.setMatchFormation(m.tournamentId, m.id, isHome, f);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 HINT AR: فريق الكابتن الحالي إن كان مشاركاً في هذه البطولة (لزر «تشكيلتي»).
  TeamModel? _myParticipatingTeam(
      TournamentDetailsLoaded state, UserModel? user) {
    if (user == null) return null;
    for (final team in state.teamsById.values) {
      if (team.captainId == user.id) return team;
    }
    return null;
  }

  // 📝 HINT AR: تصدير جدول البطولة PDF ومشاركته (بند 6).
  Future<void> _exportSchedulePdf(
      BuildContext context, TournamentDetailsLoaded state) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(ToobaSnackBar.buildInfo('جارٍ تجهيز التقرير...'));
    try {
      await FixturesPdfService.shareTournamentSchedule(
        tournament: state.tournament,
        matches: state.matches,
      );
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر تصدير التقرير'));
    }
  }

  // 📝 HINT AR: منتقي الحكم — يعرض الحكّام المتاحين (مستثنياً كابتنَي الفريقين)
  // ويعيّن المختار للمباراة عبر الكيوبت. يتيح أيضاً إلغاء التعيين.
  Future<void> _pickReferee(BuildContext context, MatchModel m) async {
    final cubit = context.read<TournamentCubit>();
    final messenger = ScaffoldMessenger.of(context);
    List<UserModel> referees;
    try {
      referees = await context.read<UserRepository>().getReferees();
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر جلب الحكّام'));
      return;
    }
    if (!context.mounted) return;
    // فصل المهام: لا يُعيَّن حكم هو كابتن أحد الفريقين.
    final state = cubit.state;
    final blocked = <String>{};
    if (state is TournamentDetailsLoaded) {
      final home = state.teamsById[m.homeTeamId];
      final away = state.teamsById[m.awayTeamId];
      if (home != null) blocked.add(home.captainId);
      if (away != null) blocked.add(away.captainId);
    }
    final available = referees.where((r) => !blocked.contains(r.id)).toList();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('اختر حكماً للمباراة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا يوجد حكّام متاحون — يمنحهم الأدمن الصلاحية',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ),
            ...available.map((r) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.sports)),
                  title: Text(r.name),
                  subtitle: Text(r.phone),
                  trailing: m.refereeId == r.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.assignReferee(
                        m.tournamentId, m.id, r.id, r.name);
                  },
                )),
            if (m.refereeId != null)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('إلغاء تعيين الحكم',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.assignReferee(m.tournamentId, m.id, null, null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: شعار فريق صغير (cache-first) أو درع افتراضي.
  Widget _teamLogo(String? url, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage:
          (url != null && url.isNotEmpty) ? ImageHelper.getProvider(url) : null,
      child: (url == null || url.isEmpty)
          ? Icon(Icons.shield, size: radius, color: Colors.grey.shade400)
          : null,
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  // 📝 HINT AR: يعرض منتقي التاريخ ثم الوقت بالتتالي. بعد الاختيار يستدعي
  // TournamentCubit.scheduleMatch لتحديث Firestore ويعكس التغيير فوراً.
  Future<void> _pickDateTime(BuildContext context, MatchModel match) async {
    final now = DateTime.now();

    // 1) اختيار التاريخ
    final date = await showDatePicker(
      context: context,
      initialDate: match.dateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      helpText: 'اختر تاريخ المباراة',
      cancelText: 'إلغاء',
      confirmText: 'التالي',
    );
    if (date == null || !context.mounted) return;

    // 2) اختيار الوقت
    final time = await showTimePicker(
      context: context,
      initialTime: match.dateTime != null
          ? TimeOfDay.fromDateTime(match.dateTime!)
          : const TimeOfDay(hour: 18, minute: 0),
      helpText: 'اختر وقت المباراة',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
    );
    if (time == null || !context.mounted) return;

    // 3) دمج التاريخ والوقت وإرسالهما للـ Cubit
    final combined = DateTime(date.year, date.month, date.day,
        time.hour, time.minute);
    context.read<TournamentCubit>().scheduleMatch(
          tournamentId,
          match.id,
          combined,
        );
  }
}

/// 📝 HINT AR: سلايدر صور إعلانات تلقائي للبطولة (PageView بلا اعتمادية إضافية)
/// + نقاط مؤشّر. الصور cache-first. يلتفّ للبداية بعد آخر صورة كل 5 ثوانٍ.
class _AdBannerSlider extends StatefulWidget {
  final List<String> images;
  const _AdBannerSlider({required this.images});

  @override
  State<_AdBannerSlider> createState() => _AdBannerSliderState();
}

class _AdBannerSliderState extends State<_AdBannerSlider> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_current + 1) % widget.images.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (c, u) => Container(color: Colors.grey.shade200),
                errorWidget: (c, u, e) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
