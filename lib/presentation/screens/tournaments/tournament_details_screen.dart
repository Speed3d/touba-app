import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/match_model.dart';
import 'enter_result_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البطولة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            return RefreshIndicator(
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
                  const SizedBox(height: 16),
                  if (t.status == 'finished' && t.winnerTeamName != null)
                    _championBanner(context, t.winnerTeamName!),
                  if (t.status == 'finished' && t.winnerTeamName != null)
                    const SizedBox(height: 16),
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
            );
          }
          if (state is TournamentError) {
            return Center(child: Text('خطأ: ${state.message}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // 📝 HINT AR: بانر تتويج البطل — يظهر عند انتهاء البطولة.
  Widget _championBanner(BuildContext context, String winnerName) {
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
          const Icon(Icons.emoji_events, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          const Text('بطل البطولة',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(winnerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ],
      ),
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
              DataCell(Text(team?.name ?? '—')),
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
                ],
              ),
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
