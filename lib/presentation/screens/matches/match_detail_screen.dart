import '../../../core/utils/image_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/match_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/services/functions_service.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../widgets/core/pitch_formation_view.dart';
import '../../widgets/core/formation_share_sheet.dart';
import '../../widgets/core/live_match_timer.dart';
import '../referee/referee_profile_screen.dart';
import '../tournaments/enter_result_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: تفاصيل المباراة — النتيجة + تشكيلة الفريقين مع أيقونات الأحداث
/// (هدف/صناعة/بطاقة/تبديل/...) بجانب اسم كل لاعب، بأسلوب جدول الدوريات.
class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final Map<String, String> _names = {};
  final Map<String, String?> _photos = {};
  final Map<String, String> _positions = {};
  List<PlayerModel> _homePlayers = [];
  List<PlayerModel> _awayPlayers = [];
  bool _showHomeFormation = true;
  bool _loading = true;
  bool _busy = false; // قيد تنفيذ إجراء حيّ (لتعطيل الأزرار)

  // 📝 HINT AR: المباراة الحيّة قابلة للتحديث (WS2) — نُعيد جلبها بعد كل إجراء.
  late MatchModel _match;
  TournamentModel? _tournament; // للمدّة/الأشواط/منظّم البطولة

  // 📝 HINT AR: سياق صلاحية تقييم الحكم (الوجبة 7 — D): منظّم البطولة + كابتنا
  // الفريقين. التقييم محصور بهؤلاء + الأدمن، مرة واحدة، والحكم لا يقيّم نفسه.
  String? _organizerUid;
  String? _homeCaptainId;
  String? _awayCaptainId;
  bool _alreadyRated = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _loadNames();
  }

  Future<void> _loadNames() async {
    // 📝 HINT AR: نلتقط كل المستودعات قبل أي await (تفادي استخدام context عبر فجوة).
    final playerRepo = context.read<PlayerRepository>();
    final teamRepo = context.read<TeamRepository>();
    final tournRepo = context.read<TournamentRepository>();
    final matchRepo = context.read<MatchRepository>();
    final m = _match;
    try {
      final home = await playerRepo.getPlayersByTeam(m.homeTeamId);
      final away = await playerRepo.getPlayersByTeam(m.awayTeamId);
      _homePlayers = home;
      _awayPlayers = away;
      for (final p in [...home, ...away]) {
        _names[p.id] = p.name;
        _photos[p.id] = p.photoUrl;
        _positions[p.id] = p.position;
      }
    } catch (_) {}
    // 📝 HINT AR: نحمّل البطولة والفريقين دائماً (للتحكّم الحيّ + سياق التقييم).
    try {
      final results = await Future.wait([
        tournRepo.getTournamentById(m.tournamentId),
        teamRepo.getTeamById(m.homeTeamId),
        teamRepo.getTeamById(m.awayTeamId),
      ]);
      _tournament = results[0] as TournamentModel;
      _organizerUid = _tournament?.organizerUid;
      _homeCaptainId = (results[1] as TeamModel).captainId;
      _awayCaptainId = (results[2] as TeamModel).captainId;
    } catch (_) {}
    // 📝 HINT AR: هل قيّمت الحكم مسبقاً؟ (لمباراة منتهية لها حكم).
    if (m.resultConfirmed && m.refereeId != null && m.refereeId!.isNotEmpty) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          _alreadyRated = (await matchRepo.getMyRefereeRating(m.id, uid)) != null;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  // 📝 HINT AR: المنظّم/الأدمن — يتحكّم بالمباراة الحيّة وإدخال النتيجة.
  bool get _canManage {
    final auth = context.read<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null) return false;
    return user.isAdmin || _organizerUid == user.id;
  }

  int get _halves => _tournament?.halvesCount ?? 2;

  // 📝 HINT AR: نُعيد جلب المباراة بعد كل إجراء حيّ ليُحدَّث العرض فوراً.
  Future<void> _refreshMatch() async {
    try {
      final m = await context.read<MatchRepository>().getMatchById(_match.id);
      if (mounted) setState(() => _match = m);
    } catch (_) {}
  }

  // ── الإجراءات الحيّة (WS2) ───────────────────────────────────────────
  Future<void> _runLive(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _refreshMatch();
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.actionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startMatch() => _runLive(
      () => context.read<MatchRepository>().startMatch(_match.id));

  void _changeLiveScore(bool isHome, int delta) {
    final h = (_match.homeScore + (isHome ? delta : 0)).clamp(0, 99);
    final a = (_match.awayScore + (!isHome ? delta : 0)).clamp(0, 99);
    _runLive(() =>
        context.read<MatchRepository>().updateLiveScore(_match.id, h, a));
  }

  void _startNextHalf() => _runLive(() => context
      .read<MatchRepository>()
      .startNextHalf(_match.id, _match.currentHalf + 1));

  Future<void> _confirmHalf() async {
    final h = _match.currentHalf;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmHalfResultX(h)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(AppLocalizations.of(context)!.halfResultText(
            h, _match.homeTeamName, _match.homeScore, _match.awayScore, _match.awayTeamName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.confirm)),
        ],
      ),
    );
    if (ok != true) return;
    await _runLive(() => context.read<MatchRepository>().confirmHalf(
        _match.id, h, _match.homeScore, _match.awayScore));
  }

  // 📝 HINT AR: إنهاء وتأكيد النتيجة النهائية — يفتح ورقة المباراة (أحداث تفصيلية
  // + حسم تعادل الإقصائي) التي تؤكّد النتيجة فتُشغّل المحرّك مرة واحدة.
  Future<void> _openFinalEntry() async {
    final repoT = context.read<TournamentRepository>();
    final repoM = context.read<MatchRepository>();
    final repoTeam = context.read<TeamRepository>();
    await Navigator.push(
      context,
      ToobaRoute.to(BlocProvider(
        create: (_) => TournamentCubit(repoT, repoM, repoTeam),
        child: EnterResultScreen(
            match: _match, tournamentId: _match.tournamentId),
      )),
    );
    await _refreshMatch();
  }

  // 📝 HINT AR: هل المُشاهد مؤهَّل لتقييم الحكم؟ (المنظّم/الأدمن/كابتن أحد الفريقين،
  // وليس الحكم نفسه). الفرض النهائي خادمي في CF rateReferee — هذا للعرض فقط.
  bool _canRate(MatchModel m) {
    final auth = context.read<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null) return false;
    if (user.id == m.refereeId) return false;
    return user.isAdmin ||
        _organizerUid == user.id ||
        _homeCaptainId == user.id ||
        _awayCaptainId == user.id;
  }

  // 📝 HINT AR: اسم اللاعب مسبوقاً بمركزه (بند 7) — «المهاجم - صلاح».
  String _displayName(String id) {
    final name = _names[id] ?? 'لاعب';
    final pos = _positions[id];
    if (pos != null && pos.isNotEmpty && pos != 'غير محدد') {
      return '$pos - $name';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final m = _match;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.matchDetails),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.detailsTab),
              Tab(text: AppLocalizations.of(context)!.formationsTab),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _detailsView(m),
                  _formationsView(m),
                ],
              ),
      ),
    );
  }

  // 📝 HINT AR: تبويب «التفاصيل» — النتيجة + تشكيلة الأحداث + تقييم الحكم (كما كان).
  Widget _detailsView(MatchModel m) {
    return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _scoreHeader(m),
                const SizedBox(height: 6),
                Center(
                  child: Text(AppLocalizations.of(context)!.roundX(m.round.toString()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
                if (m.refereeName != null && m.refereeName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports, size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.refereeNameX(m.refereeName ?? ''),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // ── حالة/تحكّم المباراة الحيّة (WS2) ──
                if (m.status == 'live') ...[
                  _liveStatusBanner(m),
                  const SizedBox(height: 12),
                ],
                if (m.periodScores.isNotEmpty) ...[
                  _periodScoresRow(m),
                  const SizedBox(height: 12),
                ],
                if (_canManage && !m.resultConfirmed) ...[
                  _liveControls(m),
                  const SizedBox(height: 16),
                ],
                if (m.resultConfirmed)
                  _lineupCard(m)
                else if (m.status == 'live')
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(AppLocalizations.of(context)!.matchInProgress,
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(AppLocalizations.of(context)!.matchNotStarted,
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                // تقييم الحكم (لمباراة منتهية لها حكم).
                if (m.resultConfirmed &&
                    m.refereeId != null &&
                    m.refereeId!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _refereeRatingCard(m),
                ],
              ],
            );
  }

  // 📝 HINT AR: تبويب «تشكيلة الفريقين» — مبدّل الفريق + الملعب. يعرض **لقطة تشكيلة
  // هذه المباراة** المحفوظة (إن وُجدت)، وإلا التشكيلة الحالية للفريق كاحتياط.
  Widget _formationsView(MatchModel m) {
    final home = _showHomeFormation;
    final snapshot = home ? m.homeLineup : m.awayLineup;
    final fmt = home ? m.homeFormation : m.awayFormation;
    final teamName = home ? m.homeTeamName : m.awayTeamName;

    final List<LineupPlayer> lineup;
    if (snapshot.isNotEmpty) {
      lineup = snapshot;
    } else {
      final live = home ? _homePlayers : _awayPlayers;
      final starters = live.where((p) => p.isStarter).toList();
      lineup = (starters.isNotEmpty ? starters : live).map(_toLineup).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _teamToggle(m),
        const SizedBox(height: 14),
        PitchFormationView(players: lineup, formation: fmt),
        const SizedBox(height: 10),
        Center(
          child: Text(
            snapshot.isNotEmpty
                ? ((fmt != null && fmt.isNotEmpty) ? AppLocalizations.of(context)!.formationWithPlan(fmt) : AppLocalizations.of(context)!.formationForThisMatch)
                : AppLocalizations.of(context)!.currentTeamFormationNotSaved,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        if (lineup.isNotEmpty)
          Center(
            child: OutlinedButton.icon(
              onPressed: () => FormationShareSheet.show(
                context,
                title: AppLocalizations.of(context)!.formationOfTeam(teamName),
                subtitle: fmt != null && fmt.isNotEmpty ? AppLocalizations.of(context)!.planX(fmt) : null,
                players: lineup,
                formation: fmt,
              ),
              icon: const Icon(Icons.share, size: 18),
              label: Text(AppLocalizations.of(context)!.shareFormation),
            ),
          ),
      ],
    );
  }

  LineupPlayer _toLineup(PlayerModel p) => LineupPlayer(
        playerId: p.id,
        name: p.name,
        photoUrl: p.photoUrl,
        position: p.position,
        shirtNumber: p.shirtNumber,
      );

  // 📝 HINT AR: مبدّل عرض تشكيلة الفريق الأول (المضيف) أو الثاني (الضيف).
  Widget _teamToggle(MatchModel m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleHalf(m.homeTeamName, _showHomeFormation,
              () => setState(() => _showHomeFormation = true)),
          _toggleHalf(m.awayTeamName, !_showHomeFormation,
              () => setState(() => _showHomeFormation = false)),
        ],
      ),
    );
  }

  Widget _toggleHalf(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1877F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // 📝 HINT AR: بطاقة تقييم الحكم — متوسطه الحالي + زر لفتح منتقي النجوم.
  Widget _refereeRatingCard(MatchModel m) {
    final repo = context.read<MatchRepository>();
    return FutureBuilder<({double rating, int count})>(
      future: repo.getRefereeProfile(m.refereeId!),
      builder: (context, snap) {
        final avg = snap.data?.rating ?? 0;
        final count = snap.data?.count ?? 0;
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    ToobaRoute.to(RefereeProfileScreen(
                        refereeUid: m.refereeId!,
                        refereeName: m.refereeName)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(AppLocalizations.of(context)!.refereeNameX(m.refereeName ?? "—"),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline)),
                      ),
                      if (count > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text('${avg.toStringAsFixed(1)} ($count)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_left,
                          size: 18, color: Colors.grey[400]),
                    ],
                  ),
                ),
                // 📝 HINT AR: زر التقييم للمؤهَّلين فقط (منظّم/أدمن/كابتن الفريقين)
                // ولمرة واحدة؛ غيرهم يرى المتوسط فقط بلا زر.
                if (_canRate(m)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _alreadyRated
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(AppLocalizations.of(context)!.ratedThisReferee),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _rateReferee(m),
                            icon: const Icon(Icons.star_outline, size: 18),
                            label: Text(AppLocalizations.of(context)!.rateRefereePerformance),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rateReferee(MatchModel m) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ToobaSnackBar.info(context, AppLocalizations.of(context)!.loginToRate);
      return;
    }
    final repo = context.read<MatchRepository>();
    int current = 0;
    try {
      current = await repo.getMyRefereeRating(m.id, uid) ?? 0;
    } catch (_) {}
    if (!mounted) return;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int stars = current;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.rateReferee),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < stars;
                return IconButton(
                  onPressed: () => setS(() => stars = i + 1),
                  icon: Icon(filled ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 32),
                );
              }),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel)),
              ElevatedButton(
                onPressed:
                    stars > 0 ? () => Navigator.pop(ctx, stars) : null,
                child: Text(AppLocalizations.of(context)!.send),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 📝 HINT AR: التقييم عبر CF (فرض الصلاحية + مرة واحدة + لا تقييم للنفس).
      await FunctionsService().rateReferee(
        refereeId: m.refereeId!,
        matchId: m.id,
        rating: selected,
      );
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.thanksForRating));
      if (mounted) setState(() => _alreadyRated = true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(_rateError(e)));
    }
  }

  // 📝 HINT AR: استخراج رسالة CF العربية الواضحة (مسبقاً/نفسك/غير مؤهَّل...).
  String _rateError(Object e) {
    if (e is FirebaseFunctionsException && (e.message ?? '').isNotEmpty) {
      return e.message!;
    }
    return AppLocalizations.of(context)!.failedToSendRating;
  }

  // ── ودجات المباراة الحيّة (WS2) ─────────────────────────────────────
  Widget _liveStatusBanner(MatchModel m) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)!.matchLive,
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(width: 10),
            LiveMatchTimer(
              startedAt: m.matchStartedAt,
              currentHalf: m.currentHalf,
              matchDuration: _tournament?.matchDuration ?? 45,
              halvesCount: _halves,
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodScoresRow(MatchModel m) {
    final parts = m.periodScores.map((e) {
      final p = Map<String, dynamic>.from(e);
      return '${AppLocalizations.of(context)!.halfX(p['period'].toString())}: ${p['home']}-${p['away']}';
    }).join('    ');
    return Center(
      child: Text(parts,
          style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    );
  }

  // 📝 HINT AR: لوحة تحكّم المنظّم/الأدمن — بدء المباراة، النتيجة اللحظية، إنهاء
  // الأشواط، والتأكيد النهائي (يفتح ورقة المباراة). تُعرض فقط للمؤهَّل وللمباراة
  // غير المؤكّدة.
  Widget _liveControls(MatchModel m) {
    if (m.status == 'upcoming') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : _startMatch,
          icon: const Icon(Icons.play_circle_fill),
          label: Text(AppLocalizations.of(context)!.startMatch),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
    if (m.status != 'live') return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(AppLocalizations.of(context)!.liveMatchControl,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _liveTeamStepper(m.homeTeamName, m.homeScore, true),
              Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey.withValues(alpha: 0.3)),
              _liveTeamStepper(m.awayTeamName, m.awayScore, false),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _confirmHalf,
                icon: const Icon(Icons.flag, size: 16),
                label: Text(AppLocalizations.of(context)!.endHalfX(m.currentHalf),
                    style: const TextStyle(fontSize: 12)),
              ),
              if (m.currentHalf < _halves)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _startNextHalf,
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: Text(AppLocalizations.of(context)!.startHalfX(m.currentHalf + 1),
                      style: const TextStyle(fontSize: 12)),
                ),
              ElevatedButton.icon(
                onPressed: _busy ? null : _openFinalEntry,
                icon: const Icon(Icons.sports_score, size: 16),
                label: Text(AppLocalizations.of(context)!.endAndConfirmResult,
                    style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveTeamStepper(String name, int score, bool isHome) {
    return Expanded(
      child: Column(
        children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _busy ? null : () => _changeLiveScore(isHome, -1),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
                visualDensity: VisualDensity.compact,
              ),
              Text('$score',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _busy ? null : () => _changeLiveScore(isHome, 1),
                icon: const Icon(Icons.add_circle),
                color: Colors.green,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreHeader(MatchModel m) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Text(
            // 📝 HINT AR: نعرض السكور أثناء «جارية» أيضاً (WS2) — «ضد» للقادمة فقط.
            (m.resultConfirmed || m.status == 'live')
                ? '${m.homeScore} - ${m.awayScore}'
                : AppLocalizations.of(context)!.versus,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          Expanded(
            child: Text(m.awayTeamName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _lineupCard(MatchModel m) {
    // تجميع الأحداث حسب اللاعب
    final Map<String, List<Map<String, dynamic>>> byPlayer = {};
    for (final raw in m.events) {
      final e = Map<String, dynamic>.from(raw);
      final pid = (e['playerId'] as String?) ?? '';
      if (pid.isEmpty) continue;
      byPlayer.putIfAbsent(pid, () => []).add(e);
    }

    if (byPlayer.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppLocalizations.of(context)!.noEventsRecorded,
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    final homePlayers = <String>[];
    final awayPlayers = <String>[];
    for (final entry in byPlayer.entries) {
      final teamId = entry.value.first['teamId'] as String? ?? '';
      if (teamId == m.homeTeamId) {
        homePlayers.add(entry.key);
      } else {
        awayPlayers.add(entry.key);
      }
    }

    final maxRows = homePlayers.length > awayPlayers.length
        ? homePlayers.length
        : awayPlayers.length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(m.homeTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(m.awayTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            Divider(height: 16, color: Colors.grey.shade300),
            ...List.generate(maxRows, (i) {
              final homeId = i < homePlayers.length ? homePlayers[i] : null;
              final awayId = i < awayPlayers.length ? awayPlayers[i] : null;
              return _playerRow(
                homeId != null
                    ? _PData(_displayName(homeId), _photos[homeId],
                        byPlayer[homeId]!)
                    : null,
                awayId != null
                    ? _PData(_displayName(awayId), _photos[awayId],
                        byPlayer[awayId]!)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(_PData? home, _PData? away) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الفريق المضيف: الاسم على اليمين، الأيقونات تجاه المنتصف
          Expanded(
            child: home != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _iconsRow(home.events),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          home.name,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _playerAvatar(home.photo),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // خط فاصل مركزي
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
          ),
          // الفريق الضيف: الاسم على اليسار، الأيقونات تجاه المنتصف
          Expanded(
            child: away != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _playerAvatar(away.photo),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          away.name,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _iconsRow(away.events),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: صورة لاعب صغيرة (assets أو شبكة cache-first) أو أيقونة افتراضية.
  Widget _playerAvatar(String? photo) {
    ImageProvider? provider;
    if (photo != null && photo.isNotEmpty) {
      provider = photo.startsWith('assets/')
          ? AssetImage(photo) as ImageProvider
          : ImageHelper.getProvider(photo);
    }
    return CircleAvatar(
      radius: 11,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: provider,
      child: provider == null
          ? Icon(Icons.person, size: 12, color: Colors.grey.shade500)
          : null,
    );
  }

  Widget _iconsRow(List<Map<String, dynamic>> events) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: events.map((e) {
        final minute = (e['minute'] as int?) ?? 0;
        // 📝 HINT AR: هدف من ركلة جزاء يُخزَّن type=goal+penalty — نعرضه بأيقونة ركلة جزاء.
        var type = e['type'] as String? ?? '';
        if (type == 'goal' && e['penalty'] == true) type = 'penalty';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _eventIcon(type),
              if (minute > 0)
                Text(
                  "$minute'",
                  style: const TextStyle(
                      fontSize: 9, color: Colors.grey, height: 1.2),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── أيقونات الأحداث ───────────────────────────────────────────────
  static Widget _eventIcon(String type) {
    switch (type) {
      case 'goal':
        return const Icon(Icons.sports_soccer, color: Colors.green, size: 16);
      case 'owngoal':
        return const Icon(Icons.sports_soccer, color: Colors.red, size: 16);
      case 'assist':
        return const Text('👟', style: TextStyle(fontSize: 13, height: 1));
      case 'yellow':
        return _cardWidget(Colors.amber);
      case 'red':
        return _cardWidget(Colors.red);
      case 'yellow_red':
        return SizedBox(
          width: 18,
          height: 14,
          child: Stack(
            children: [
              Positioned(left: 5, child: _cardWidget(Colors.red)),
              _cardWidget(Colors.amber),
            ],
          ),
        );
      case 'sub_in':
        return const Icon(Icons.arrow_upward_rounded,
            color: Colors.green, size: 16);
      case 'sub_out':
        return const Icon(Icons.arrow_downward_rounded,
            color: Colors.red, size: 16);
      case 'injury':
        return Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
              color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 10),
        );
      case 'suspension':
        return const Icon(Icons.not_interested_rounded,
            color: Colors.red, size: 16);
      case 'penalty':
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.sports_soccer, color: Colors.green, size: 10),
        );
      case 'penalty_miss':
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.close, color: Colors.red, size: 10),
        );
      case 'var':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade500),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text('VAR',
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700])),
        );
      default:
        return const Icon(Icons.circle, size: 6, color: Colors.grey);
    }
  }

  static Widget _cardWidget(Color color) {
    return Container(
      width: 10,
      height: 14,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _PData {
  final String name;
  final String? photo;
  final List<Map<String, dynamic>> events;
  _PData(this.name, this.photo, this.events);
}
