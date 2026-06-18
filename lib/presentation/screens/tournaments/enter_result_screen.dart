import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: شاشة إدخال نتيجة المباراة بأسلوب «ورقة المباراة»: قسمان (فريق
/// لكل جهة)، تحت كل فريق لاعبوه، ولكل لاعب عدّادات +/− لـ (هدف/صناعة/إنذار/طرد).
/// النتيجة تُحسب تلقائياً من مجموع الأهداف. قاعدة: إنذاران ⟵ طرد تلقائي.
/// عند الحفظ تُؤكَّد النتيجة فتُشغّل Cloud Function لتحديث الترتيب وإحصائيات اللاعبين.
class EnterResultScreen extends StatefulWidget {
  final MatchModel match;
  final String tournamentId;
  const EnterResultScreen({
    super.key,
    required this.match,
    required this.tournamentId,
  });

  @override
  State<EnterResultScreen> createState() => _EnterResultScreenState();
}

/// عدّادات حدث لاعب واحد (قابلة للتعديل).
class _Counts {
  int goals = 0;
  int assists = 0;
  int yellow = 0;
  int red = 0;
}

class _EnterResultScreenState extends State<EnterResultScreen> {
  final Map<String, _Counts> _counts = {};
  List<PlayerModel> _homePlayers = [];
  List<PlayerModel> _awayPlayers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRosters();
  }

  Future<void> _loadRosters() async {
    try {
      final repo = context.read<PlayerRepository>();
      final home = await repo.getPlayersByTeam(widget.match.homeTeamId);
      final away = await repo.getPlayersByTeam(widget.match.awayTeamId);
      for (final p in [...home, ...away]) {
        _counts[p.id] = _Counts();
      }
      // تعبئة الأحداث الموجودة مسبقاً (عند تعديل نتيجة مؤكّدة).
      for (final e in widget.match.events) {
        final ev = Map<String, dynamic>.from(e);
        final c = _counts[ev['playerId']];
        if (c == null) continue;
        switch (ev['type']) {
          case 'goal':
            c.goals++;
            break;
          case 'assist':
            c.assists++;
            break;
          case 'yellow':
            c.yellow++;
            break;
          case 'red':
            c.red++;
            break;
        }
      }
      if (mounted) {
        setState(() {
          _homePlayers = home;
          _awayPlayers = away;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _teamGoals(List<PlayerModel> players) =>
      players.fold(0, (s, p) => s + (_counts[p.id]?.goals ?? 0));

  void _change(String playerId, String field, int delta) {
    final c = _counts[playerId];
    if (c == null) return;
    setState(() {
      switch (field) {
        case 'goals':
          c.goals = (c.goals + delta).clamp(0, 99);
          break;
        case 'assists':
          c.assists = (c.assists + delta).clamp(0, 99);
          break;
        case 'yellow':
          c.yellow = (c.yellow + delta).clamp(0, 2);
          // قاعدة: إنذاران = طرد تلقائي.
          if (c.yellow >= 2) c.red = 1;
          break;
        case 'red':
          c.red = (c.red + delta).clamp(0, 1);
          break;
      }
    });
  }

  void _save() {
    final events = <Map<String, dynamic>>[];
    void addFor(List<PlayerModel> players, String teamId) {
      for (final p in players) {
        final c = _counts[p.id]!;
        for (var i = 0; i < c.goals; i++) {
          events.add({'type': 'goal', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
        }
        for (var i = 0; i < c.assists; i++) {
          events.add({'type': 'assist', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
        }
        for (var i = 0; i < c.yellow; i++) {
          events.add({'type': 'yellow', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
        }
        for (var i = 0; i < c.red; i++) {
          events.add({'type': 'red', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
        }
      }
    }

    addFor(_homePlayers, widget.match.homeTeamId);
    addFor(_awayPlayers, widget.match.awayTeamId);

    // 📝 HINT AR: التشكيلة = كل لاعبي الفريقين (لاحتساب «مباريات» لكل لاعب).
    final lineup = [
      ..._homePlayers.map((p) => p.id),
      ..._awayPlayers.map((p) => p.id),
    ];

    context.read<TournamentCubit>().enterResult(
          widget.tournamentId,
          widget.match,
          _teamGoals(_homePlayers),
          _teamGoals(_awayPlayers),
          events: events,
          lineup: lineup,
        );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final theme = Theme.of(context);
    return BlocListener<TournamentCubit, TournamentState>(
      listener: (context, state) {
        if (state is TournamentActionSuccess) {
          Navigator.pop(context);
        } else if (state is TournamentError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدخال النتيجة'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        bottomNavigationBar: _loading
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('حفظ وتأكيد النتيجة',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // النتيجة المحسوبة تلقائياً من الأهداف
                  _scoreHeader(theme, m),
                  const SizedBox(height: 16),
                  _teamSection(m.homeTeamName, _homePlayers),
                  const SizedBox(height: 16),
                  _teamSection(m.awayTeamName, _awayPlayers),
                  const SizedBox(height: 8),
                  Text(
                    'النتيجة تُحسب تلقائياً من الأهداف. قاعدة: إنذاران = طرد.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _scoreHeader(ThemeData theme, MatchModel m) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1877F2), Color(0xFF0C5EBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(m.homeTeamName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Text(
            '${_teamGoals(_homePlayers)} - ${_teamGoals(_awayPlayers)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          Expanded(
            child: Text(m.awayTeamName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _teamSection(String teamName, List<PlayerModel> players) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(teamName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary)),
          ),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('لا لاعبون مسجّلون في هذا الفريق',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            )
          else
            ...players.map(_playerRow),
        ],
      ),
    );
  }

  Widget _playerRow(PlayerModel p) {
    final c = _counts[p.id]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stepper('هدف', Colors.green, c.goals,
                  () => _change(p.id, 'goals', 1), () => _change(p.id, 'goals', -1)),
              _stepper('صناعة', Colors.blue, c.assists,
                  () => _change(p.id, 'assists', 1), () => _change(p.id, 'assists', -1)),
              _stepper('إنذار', Colors.amber, c.yellow,
                  () => _change(p.id, 'yellow', 1), () => _change(p.id, 'yellow', -1)),
              _stepper('طرد', Colors.red, c.red,
                  () => _change(p.id, 'red', 1), () => _change(p.id, 'red', -1)),
            ],
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }

  Widget _stepper(String label, Color color, int value, VoidCallback onPlus,
      VoidCallback onMinus) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniBtn(Icons.remove, onMinus),
              Container(
                width: 22,
                alignment: Alignment.center,
                child: Text('$value',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              _miniBtn(Icons.add, onPlus, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: color ?? Colors.grey[700]),
      ),
    );
  }
}
