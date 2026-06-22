import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/match_repository.dart';
import '../../widgets/core/tooba_match_card.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'match_detail_screen.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: مباريات بطولة واحدة فقط — ثلاثة تبويبات (جارية/قادمة/انتهت)
/// مجمَّعة باليوم. لا تداخل مع بطولات أخرى.
class TournamentMatchesScreen extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentMatchesScreen({super.key, required this.tournament});

  @override
  State<TournamentMatchesScreen> createState() =>
      _TournamentMatchesScreenState();
}

class _TournamentMatchesScreenState extends State<TournamentMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<MatchModel>> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _future = context
        .read<MatchRepository>()
        .getMatchesByTournament(widget.tournament.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final f = context
        .read<MatchRepository>()
        .getMatchesByTournament(widget.tournament.id);
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'جارية'),
            Tab(text: 'قادمة'),
            Tab(text: 'انتهت'),
          ],
        ),
      ),
      body: FutureBuilder<List<MatchModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return TabBarView(
              controller: _tabController,
              children: List.generate(
                3,
                (_) => const ToobaShimmerList(count: 5, tileHeight: 90),
              ),
            );
          }
          if (snapshot.hasError) {
            return ToobaEmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'تعذّر تحميل المباريات',
              subtitle: snapshot.error.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: _reload,
            );
          }

          final all = snapshot.data ?? [];
          final now = DateTime.now();
          final live = all.where((m) => m.status == 'live').toList();
          final upcoming = all
              .where((m) => !m.resultConfirmed && m.status != 'live')
              .toList()
            ..sort((a, b) {
              if (a.dateTime == null && b.dateTime == null) return 0;
              if (a.dateTime == null) return 1;
              if (b.dateTime == null) return -1;
              return a.dateTime!.compareTo(b.dateTime!);
            });
          final finished = all.where((m) => m.resultConfirmed).toList()
            ..sort((a, b) {
              if (a.dateTime == null && b.dateTime == null) return 0;
              if (a.dateTime == null) return 1;
              if (b.dateTime == null) return -1;
              return b.dateTime!.compareTo(a.dateTime!);
            });

          return RefreshIndicator(
            onRefresh: _reload,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(context, live, 'لا توجد مباريات جارية الآن', now),
                _buildList(context, upcoming, 'لا توجد مباريات قادمة', now),
                _buildList(context, finished, 'لا توجد مباريات منتهية', now),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<MatchModel> matches,
      String emptyMsg, DateTime now) {
    if (matches.isEmpty) {
      return ToobaEmptyState(
          icon: Icons.sports_soccer_outlined, title: emptyMsg);
    }
    final Map<String, List<MatchModel>> byDate = {};
    for (final m in matches) {
      final key = m.dateTime != null
          ? DateFormat('yyyy-MM-dd').format(m.dateTime!)
          : '__no_date__';
      byDate.putIfAbsent(key, () => []).add(m);
    }
    final items = <Widget>[];
    for (final dateKey in byDate.keys) {
      final label = dateKey == '__no_date__'
          ? 'موعد غير محدد'
          : _formatDateHeader(DateTime.parse(dateKey), now);
      items.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13)),
      ));
      for (final m in byDate[dateKey]!) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(
                context, ToobaRoute.to(MatchDetailScreen(match: m))),
            child: ToobaMatchCard(
              homeTeamName: m.homeTeamName,
              awayTeamName: m.awayTeamName,
              homeTeamLogo: m.homeTeamLogo,
              awayTeamLogo: m.awayTeamLogo,
              homeScore: m.resultConfirmed ? m.homeScore : null,
              awayScore: m.resultConfirmed ? m.awayScore : null,
              timeText: _formatMatchTime(m, now),
              isLive: m.status == 'live',
              dateTime: m.dateTime,
            ),
          ),
        ));
      }
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: items,
    );
  }

  String _formatDateHeader(DateTime dt, DateTime now) {
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isTomorrow = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day + 1;
    if (isToday) return 'اليوم';
    if (isTomorrow) return 'غداً';
    return DateFormat('EEEE، d MMMM', 'ar').format(dt);
  }

  String _formatMatchTime(MatchModel m, DateTime now) {
    if (m.resultConfirmed) return 'انتهت';
    if (m.status == 'live') return 'مباشر';
    if (m.dateTime == null) return 'الجولة ${m.round}';
    final dt = m.dateTime!;
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isTomorrow = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day + 1;
    if (isToday) return 'اليوم ${DateFormat('HH:mm').format(dt)}';
    if (isTomorrow) return 'غداً ${DateFormat('HH:mm').format(dt)}';
    return DateFormat('d MMM • HH:mm', 'ar').format(dt);
  }
}
