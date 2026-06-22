import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/player_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../widgets/core/pitch_formation_view.dart';
import '../../widgets/core/formation_share_sheet.dart';

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
  List<PlayerModel> _homePlayers = [];
  List<PlayerModel> _awayPlayers = [];
  bool _showHomeFormation = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final repo = context.read<PlayerRepository>();
      final home = await repo.getPlayersByTeam(widget.match.homeTeamId);
      final away = await repo.getPlayersByTeam(widget.match.awayTeamId);
      _homePlayers = home;
      _awayPlayers = away;
      for (final p in [...home, ...away]) {
        _names[p.id] = p.name;
        _photos[p.id] = p.photoUrl;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل المباراة'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'التفاصيل'),
              Tab(text: 'تشكيلة الفريقين'),
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
                  child: Text('الجولة ${m.round}',
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
                        Text('الحكم: ${m.refereeName}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (!m.resultConfirmed)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('لم تُلعب المباراة بعد',
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  )
                else
                  _lineupCard(m),
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
                ? 'تشكيلة هذه المباراة${fmt != null && fmt.isNotEmpty ? ' • خطة $fmt' : ''}'
                : 'التشكيلة الحالية للفريق (لم تُحفظ بعد لهذه المباراة)',
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
                title: 'تشكيلة $teamName',
                subtitle: fmt != null && fmt.isNotEmpty ? 'خطة $fmt' : null,
                players: lineup,
                formation: fmt,
              ),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('مشاركة التشكيلة'),
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
                Row(
                  children: [
                    const Icon(Icons.sports, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('الحكم: ${m.refereeName ?? "—"}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (count > 0) ...[
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text('${avg.toStringAsFixed(1)} ($count)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _rateReferee(m),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('قيّم أداء الحكم'),
                  ),
                ),
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
      ToobaSnackBar.info(context, 'سجّل الدخول للتقييم');
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
            title: const Text('تقييم الحكم'),
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
                  child: const Text('إلغاء')),
              ElevatedButton(
                onPressed:
                    stars > 0 ? () => Navigator.pop(ctx, stars) : null,
                child: const Text('إرسال'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.rateReferee(
        refereeId: m.refereeId!,
        matchId: m.id,
        raterId: uid,
        rating: selected,
      );
      messenger.showSnackBar(ToobaSnackBar.buildSuccess('شكراً لتقييمك!'));
      if (mounted) setState(() {}); // لتحديث المتوسط
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر إرسال التقييم'));
    }
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
            m.resultConfirmed ? '${m.homeScore} - ${m.awayScore}' : 'ضد',
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
          child: Text('لم تُسجَّل أحداث لهذه المباراة',
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
                    ? _PData(_names[homeId] ?? 'لاعب', _photos[homeId],
                        byPlayer[homeId]!)
                    : null,
                awayId != null
                    ? _PData(_names[awayId] ?? 'لاعب', _photos[awayId],
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
          : CachedNetworkImageProvider(photo);
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
