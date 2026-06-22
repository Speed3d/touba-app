import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import 'enter_result_screen.dart';
import 'tournament_rules_editor.dart';
import '../matches/match_detail_screen.dart';
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
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البطولة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: const TabBar(
          tabs: [
            Tab(text: 'تفاصيل'),
            Tab(text: 'شروط وقوانين'),
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
                  // 📝 HINT AR: تقديم طلب تحكيم — لأي مستخدم ليس منظّم/أدمن.
                  if (currentUser != null && !canManage &&
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
                  _standingsTable(context, state),
                  const SizedBox(height: 24),
                  Text('المباريات',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._matchTiles(context, state, canManage),
                  const SizedBox(height: 24),
                ],
              ),
                ),
                // ── تبويب «شروط وقوانين» ──
                _rulesTab(context, state, canManage),
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
                          ? CachedNetworkImageProvider(s.logoUrl)
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

  // 📝 HINT AR: بانر تتويج البطل عند انتهاء البطولة — كأس/شعار البطل + الجوائز
  // + الراعي (يضبطها الأدمن من «إدارة البطولات»).
  Widget _championBanner(
      BuildContext context, TournamentModel t, TournamentDetailsLoaded state) {
    final winnerTeam = state.teamsById[t.winnerTeamId];
    final cupOrLogo = (t.cupImageUrl != null && t.cupImageUrl!.isNotEmpty)
        ? CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            backgroundImage: CachedNetworkImageProvider(t.cupImageUrl!),
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

  Widget _standingsTable(BuildContext context, TournamentDetailsLoaded state) {
    final standings = state.standings;
    if (standings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text('سيظهر الترتيب بعد إدخال أول نتيجة',
            style: TextStyle(color: Colors.grey[600])),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('الفريق')),
            DataColumn(label: Text('ل')),
            DataColumn(label: Text('ف')),
            DataColumn(label: Text('ت')),
            DataColumn(label: Text('خ')),
            DataColumn(label: Text('±')),
            DataColumn(label: Text('نقاط')),
          ],
          rows: List.generate(standings.length, (i) {
            final s = Map<String, dynamic>.from(standings[i]);
            final team = state.teamsById[s['teamId']];
            final total = standings.length;
            return DataRow(cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _rankDot(i + 1, total),
                  const SizedBox(width: 4),
                  Text('${i + 1}'),
                ],
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _teamLogo(team?.logoUrl, 12),
                  const SizedBox(width: 6),
                  Text(team?.name ?? '—'),
                ],
              )),
              DataCell(Text('${s['played'] ?? 0}')),
              DataCell(Text('${s['won'] ?? 0}')),
              DataCell(Text('${s['drawn'] ?? 0}')),
              DataCell(Text('${s['lost'] ?? 0}')),
              DataCell(Text('${s['gd'] ?? 0}')),
              DataCell(Text('${s['points'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
            ]);
          }),
        ),
      ),
    );
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
        tiles.add(_matchTile(context, m, canManage));
      }
    }
    return tiles;
  }

  Widget _matchTile(
      BuildContext context, MatchModel m, bool canManage) {
    final theme = Theme.of(context);
    final finished = m.resultConfirmed;
    final hasDate = m.dateTime != null;
    final dateLabel = hasDate
        ? DateFormat('EEE d MMM • HH:mm', 'ar').format(m.dateTime!)
        : 'موعد غير محدد';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: finished
            ? () => Navigator.push(
                  context,
                  ToobaRoute.to(MatchDetailScreen(match: m)),
                )
            : null,
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
                  if (!finished && !hasDate && canManage)
                    _badge('بدون موعد', Colors.orange.shade100,
                        Colors.orange.shade700),
                  if (!finished && hasDate && m.dateTime!.isAfter(DateTime.now()))
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
              // ── أزرار المنظّم ──
              if (canManage && !finished) ...[
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

  // 📝 HINT AR: دائرة خضراء للمراكز الأولى (ترقية)، حمراء للأخيرة (هبوط).
  Widget _rankDot(int rank, int total) {
    Color? color;
    if (rank <= 2) {
      color = Colors.green;
    } else if (total >= 4 && rank >= total - 1) {
      color = Colors.red;
    }
    if (color == null) return const SizedBox(width: 10);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          (url != null && url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
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

// 📝 HINT AR: امتداد مساعد لقراءة standings كقائمة من الحالة.
extension on TournamentDetailsLoaded {
  List<dynamic> get standings => tournament.standings;
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
