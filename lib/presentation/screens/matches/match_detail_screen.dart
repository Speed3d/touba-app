import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/player_repository.dart';

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
      for (final p in [...home, ...away]) {
        _names[p.id] = p.name;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المباراة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _scoreHeader(m),
                const SizedBox(height: 6),
                Center(
                  child: Text('الجولة ${m.round}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
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
                    ? _PData(_names[homeId] ?? 'لاعب', byPlayer[homeId]!)
                    : null,
                awayId != null
                    ? _PData(_names[awayId] ?? 'لاعب', byPlayer[awayId]!)
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

  Widget _iconsRow(List<Map<String, dynamic>> events) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: events.map((e) {
        final minute = (e['minute'] as int?) ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _eventIcon(e['type'] as String? ?? ''),
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
      case 'own_goal':
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
  final List<Map<String, dynamic>> events;
  _PData(this.name, this.events);
}
