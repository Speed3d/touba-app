import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

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
  int penalties = 0; // أهداف من ركلة جزاء (تُحتسب هدفاً)
  int ownGoals = 0; // أهداف بالخطأ (تُحتسب لخصمه)
  bool injured = false; // إصابة
}

class _EnterResultScreenState extends State<EnterResultScreen> {
  final Map<String, _Counts> _counts = {};
  List<PlayerModel> _homePlayers = [];
  List<PlayerModel> _awayPlayers = [];
  TeamModel? _homeTeam;
  TeamModel? _awayTeam;
  bool _loading = true;

  // 📝 HINT AR: حسم تعادل الإقصائي (الوجبة 7) — يظهر فقط لمباراة إقصائية متعادلة.
  String _decidedBy = 'extratime_penalties';
  String? _advancedTeamId;
  int _penHome = 0;
  int _penAway = 0;

  bool get _isKnockout => widget.match.stage == 'knockout';
  bool get _isDraw =>
      _scoreFor(_homePlayers, _awayPlayers) ==
      _scoreFor(_awayPlayers, _homePlayers);

  @override
  void initState() {
    super.initState();
    _loadRosters();
    // 📝 HINT AR: نبدأ بطريقة الحسم المعتمدة عند إنشاء البطولة (إن توفّرت الحالة).
    final st = context.read<TournamentCubit>().state;
    if (st is TournamentDetailsLoaded) {
      _decidedBy = st.tournament.tieBreakMode;
    }
    // قيم الجزاءات الموجودة مسبقاً (عند تعديل نتيجة محسومة).
    _advancedTeamId = widget.match.advancedTeamId;
    if (widget.match.decidedBy != 'none') _decidedBy = widget.match.decidedBy;
    _penHome = widget.match.penaltyHome ?? 0;
    _penAway = widget.match.penaltyAway ?? 0;
  }

  Future<void> _loadRosters() async {
    try {
      final repo = context.read<PlayerRepository>();
      final teamRepo = context.read<TeamRepository>();
      final home = await repo.getPlayersByTeam(widget.match.homeTeamId);
      final away = await repo.getPlayersByTeam(widget.match.awayTeamId);
      // 📝 HINT AR: نحمّل الفريقين لالتقاط خطّتهما ضمن لقطة المباراة.
      try {
        _homeTeam = await teamRepo.getTeamById(widget.match.homeTeamId);
        _awayTeam = await teamRepo.getTeamById(widget.match.awayTeamId);
      } catch (_) {}
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
            // 📝 HINT AR: ركلة الجزاء تُخزَّن كهدف بعلامة penalty.
            if (ev['penalty'] == true) {
              c.penalties++;
            } else {
              c.goals++;
            }
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
          case 'owngoal':
            c.ownGoals++;
            break;
          case 'injury':
            c.injured = true;
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

  // 📝 HINT AR: نتيجة فريق = أهدافه (عادية + ركلات جزاء) + أهداف الخصم بالخطأ.
  int _scoreFor(List<PlayerModel> own, List<PlayerModel> opp) {
    int s = 0;
    for (final p in own) {
      final c = _counts[p.id];
      if (c != null) s += c.goals + c.penalties;
    }
    for (final p in opp) {
      s += _counts[p.id]?.ownGoals ?? 0;
    }
    return s;
  }

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
        case 'penalties':
          c.penalties = (c.penalties + delta).clamp(0, 99);
          break;
        case 'ownGoals':
          c.ownGoals = (c.ownGoals + delta).clamp(0, 99);
          break;
      }
    });
  }

  void _toggleInjured(String playerId) {
    final c = _counts[playerId];
    if (c == null) return;
    setState(() => c.injured = !c.injured);
  }

  void _save() {
    // 📝 HINT AR: الإقصائي لا يقبل تعادلاً — يجب تحديد المتأهّل (يصعد في الشجرة).
    if (_isKnockout && _isDraw &&
        (_advancedTeamId == null || _advancedTeamId!.isEmpty)) {
      ToobaSnackBar.warning(
          context, AppLocalizations.of(context)!.selectAdvancedTeamNoDrawInKnockout);
      return;
    }
    final events = <Map<String, dynamic>>[];
    void addFor(List<PlayerModel> players, String teamId) {
      for (final p in players) {
        final c = _counts[p.id]!;
        for (var i = 0; i < c.goals; i++) {
          events.add({'type': 'goal', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
        }
        // 📝 HINT AR: ركلة جزاء = هدف بعلامة penalty (يحتسبها CF هدفاً للاعب).
        for (var i = 0; i < c.penalties; i++) {
          events.add({'type': 'goal', 'penalty': true, 'playerId': p.id, 'teamId': teamId, 'minute': 0});
        }
        // هدف بالخطأ = owngoal (يُحتسب لنتيجة الخصم، لا لإحصائيات اللاعب).
        for (var i = 0; i < c.ownGoals; i++) {
          events.add({'type': 'owngoal', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
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
        if (c.injured) {
          events.add({'type': 'injury', 'playerId': p.id, 'teamId': teamId, 'minute': 0});
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

    // 📝 HINT AR: لقطة تشكيلة كل فريق (الأساسيون، أو الكل إن لم يُحدَّد أساسيون)
    // تُحفظ بالمباراة فتبقى ثابتة لهذه اللعبة بعينها.
    List<Map<String, dynamic>> snap(List<PlayerModel> ps) {
      final starters = ps.where((p) => p.isStarter).toList();
      final use = starters.isNotEmpty ? starters : ps;
      return use
          .map((p) => LineupPlayer(
                playerId: p.id,
                name: p.name,
                photoUrl: p.photoUrl,
                position: p.position,
                shirtNumber: p.shirtNumber,
              ).toJson())
          .toList();
    }

    context.read<TournamentCubit>().enterResult(
          widget.tournamentId,
          widget.match,
          _scoreFor(_homePlayers, _awayPlayers),
          _scoreFor(_awayPlayers, _homePlayers),
          events: events,
          lineup: lineup,
          homeLineup: snap(_homePlayers),
          awayLineup: snap(_awayPlayers),
          homeFormation: _homeTeam?.formation,
          awayFormation: _awayTeam?.formation,
          decidedBy: _isKnockout && _isDraw ? _decidedBy : null,
          penaltyHome: _isKnockout && _isDraw ? _penHome : null,
          penaltyAway: _isKnockout && _isDraw ? _penAway : null,
          advancedTeamId: _isKnockout && _isDraw ? _advancedTeamId : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final theme = Theme.of(context);
    return BlocListener<TournamentCubit, TournamentState>(
      listener: (context, state) {
        if (state is TournamentActionSuccess) {
          ToobaSnackBar.success(context, AppLocalizations.of(context)!.tournamentSuccessResultEntered);
          Navigator.pop(context);
        } else if (state is TournamentError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.enterResultTitle),
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
                    child: Text(AppLocalizations.of(context)!.saveAndConfirmResultBtn,
                        style:
                            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  // 📝 HINT AR: حسم التعادل — يظهر فقط لمباراة إقصائية متعادلة.
                  if (_isKnockout && _isDraw) ...[
                    const SizedBox(height: 16),
                    _tieBreakCard(m),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.resultCalculatedAutomatically,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  // 📝 HINT AR: بطاقة حسم تعادل الإقصائي — طريقة الحسم + ركلات الترجيح + المتأهّل.
  // النتيجة الأصلية تبقى تعادلاً؛ المتأهّل (advancedTeamId) يصعد في الشجرة عبر CF.
  Widget _tieBreakCard(MatchModel m) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: Colors.amber.shade800, size: 18),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context)!.tieBreakKnockoutStage,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context)!.tieBreakMethod, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.extraTimeThenPenalties),
                selected: _decidedBy == 'extratime_penalties',
                onSelected: (_) =>
                    setState(() => _decidedBy = 'extratime_penalties'),
              ),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.straightToPenalties),
                selected: _decidedBy == 'penalties',
                onSelected: (_) => setState(() => _decidedBy = 'penalties'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.penaltyShootoutOptional, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _penStepper(m.homeTeamName, true)),
              const SizedBox(width: 12),
              Expanded(child: _penStepper(m.awayTeamName, false)),
            ],
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.advancedTeamToNextRound,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(m.homeTeamName),
                selected: _advancedTeamId == m.homeTeamId,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                onSelected: (_) =>
                    setState(() => _advancedTeamId = m.homeTeamId),
              ),
              ChoiceChip(
                label: Text(m.awayTeamName),
                selected: _advancedTeamId == m.awayTeamId,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                onSelected: (_) =>
                    setState(() => _advancedTeamId = m.awayTeamId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _penStepper(String teamName, bool isHome) {
    final value = isHome ? _penHome : _penAway;
    return Column(
      children: [
        Text(teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _miniBtn(Icons.remove, () => setState(() {
                  if (isHome) {
                    _penHome = (_penHome - 1).clamp(0, 99);
                  } else {
                    _penAway = (_penAway - 1).clamp(0, 99);
                  }
                })),
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Text('$value',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _miniBtn(Icons.add, () => setState(() {
                  if (isHome) {
                    _penHome = (_penHome + 1).clamp(0, 99);
                  } else {
                    _penAway = (_penAway + 1).clamp(0, 99);
                  }
                }), color: Colors.green),
          ],
        ),
      ],
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
            '${_scoreFor(_homePlayers, _awayPlayers)} - ${_scoreFor(_awayPlayers, _homePlayers)}',
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
              child: Text(AppLocalizations.of(context)!.noPlayersRegisteredInTeam,
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
              // 📝 HINT AR: مركز اللاعب بجانب اسمه (بند 7) — «المهاجم - صلاح».
              if (p.position != 'غير محدد') ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(p.position,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ),
                const SizedBox(width: 6),
              ],
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
              _stepper(AppLocalizations.of(context)!.goalEvent, Colors.green, c.goals,
                  () => _change(p.id, 'goals', 1), () => _change(p.id, 'goals', -1)),
              _stepper(AppLocalizations.of(context)!.assistEvent, Colors.blue, c.assists,
                  () => _change(p.id, 'assists', 1), () => _change(p.id, 'assists', -1)),
              _stepper(AppLocalizations.of(context)!.yellowCardEvent, Colors.amber, c.yellow,
                  () => _change(p.id, 'yellow', 1), () => _change(p.id, 'yellow', -1)),
              _stepper(AppLocalizations.of(context)!.redCardEvent, Colors.red, c.red,
                  () => _change(p.id, 'red', 1), () => _change(p.id, 'red', -1)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stepper(AppLocalizations.of(context)!.penaltyEvent, Colors.green.shade800, c.penalties,
                  () => _change(p.id, 'penalties', 1),
                  () => _change(p.id, 'penalties', -1)),
              _stepper(AppLocalizations.of(context)!.ownGoalEvent, Colors.redAccent, c.ownGoals,
                  () => _change(p.id, 'ownGoals', 1),
                  () => _change(p.id, 'ownGoals', -1)),
              // إصابة — زرّ تبديل بسيط.
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.injuryEvent,
                        style: const TextStyle(fontSize: 10, color: Colors.red)),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _toggleInjured(p.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (c.injured ? Colors.red : Colors.grey)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          c.injured ? Icons.healing : Icons.add,
                          size: 16,
                          color: c.injured ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()), // محاذاة (عمود فارغ)
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
