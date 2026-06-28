import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../widgets/core/standings_view.dart';
import '../../widgets/core/bracket_view.dart';
import '../matches/match_detail_screen.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: شاشة «جدول الترتيب» (الوجبة 7 — بند 11) لبطولة. تعرض:
/// • دوري → جدول الترتيب. • مجموعات → جدول كل مجموعة + الشجرة (إن وُلِّدت).
/// • خروج مغلوب → الشجرة. تُفتح من كارت داخل شاشة مباريات البطولة.
class TournamentStandingsScreen extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentStandingsScreen({super.key, required this.tournament});

  @override
  State<TournamentStandingsScreen> createState() =>
      _TournamentStandingsScreenState();
}

class _TournamentStandingsScreenState extends State<TournamentStandingsScreen> {
  TournamentModel? _tournament;
  Map<String, TeamModel> _teamsById = {};
  List<MatchModel> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tournRepo = context.read<TournamentRepository>();
    final teamRepo = context.read<TeamRepository>();
    final matchRepo = context.read<MatchRepository>();
    try {
      // 📝 HINT AR: نُحدّث البطولة (للترتيب الأحدث) + الفرق + المباريات (للشجرة).
      final results = await Future.wait([
        tournRepo.getTournamentById(widget.tournament.id),
        teamRepo.getTeamsByIds(widget.tournament.teamIds),
        matchRepo.getMatchesByTournament(widget.tournament.id),
      ]);
      final t = results[0] as TournamentModel;
      final teams = results[1] as List<TeamModel>;
      final matches = results[2] as List<MatchModel>;
      if (!mounted) return;
      setState(() {
        _tournament = t;
        _teamsById = {for (final team in teams) team.id: team};
        _matches = matches;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tournament ?? widget.tournament;
    final knockoutMatches =
        _matches.where((m) => m.stage == 'knockout').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('جدول الترتيب'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (t.type != 'knockout')
                    StandingsView(
                        standings: t.standings, teamsById: _teamsById),
                  if (knockoutMatches.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.account_tree,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('المرحلة الإقصائية',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BracketView(
                      matches: knockoutMatches,
                      onMatchTap: (m) => Navigator.push(context,
                          ToobaRoute.to(MatchDetailScreen(match: m))),
                    ),
                  ],
                  if (t.type == 'knockout' && knockoutMatches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('لم تُولَّد الشجرة بعد',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
