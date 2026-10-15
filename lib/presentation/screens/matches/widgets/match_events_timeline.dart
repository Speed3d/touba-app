import 'package:flutter/material.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../data/models/match_model.dart';
import '../../../../l10n/app_localizations.dart';

/// 📝 HINT AR: ودجت جدول أحداث المباراة — يعرض كل لاعب مع أيقونات الأحداث الخاصة به
/// (أهداف، إنذارات، تبديلات، إلخ) مقسمة بين الفريق المضيف والضيف.
class MatchEventsTimeline extends StatelessWidget {
  final MatchModel match;
  final Map<String, String> names;
  final Map<String, String?> photos;
  final Map<String, String> positions;

  const MatchEventsTimeline({
    super.key,
    required this.match,
    required this.names,
    required this.photos,
    required this.positions,
  });

  String _displayName(String id) {
    final name = names[id] ?? 'لاعب';
    final pos = positions[id];
    if (pos != null && pos.isNotEmpty && pos != 'غير محدد') {
      return '$pos - $name';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> byPlayer = {};
    for (final raw in match.events) {
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
      if (teamId == match.homeTeamId) {
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
                  child: Text(match.homeTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(match.awayTeamName,
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
                    ? _PData(_displayName(homeId), photos[homeId],
                        byPlayer[homeId]!)
                    : null,
                awayId != null
                    ? _PData(_displayName(awayId), photos[awayId],
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
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
          ),
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
