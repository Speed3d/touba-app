import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/match_model.dart';
import '../../../core/utils/formations.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: عرض تشكيلة فريق على أرضية الملعب (المرحلة 6). الأرضية أصل مرفق
/// (`assets/images/pitch.jpg`) — لا تستهلك بيانات إنترنت. أفقية فتُدوّر 90° لتصير
/// عمودية (المرمى أسفل، الهجوم أعلى).
///
/// إن مُرِّرت [formation] (صيغة «1-2-2-1») تُرسم خاناتها الثابتة ويُملأ كل خط
/// بلاعبيه حسب المركز (حارس/مدافع/وسط/مهاجم؛ «غير محدد»→وسط)؛ الخانات الفارغة
/// تظهر باهتة لإيضاح شكل الخطة. وإلا تُرتَّب تلقائياً حسب أعداد المراكز الفعلية.
class PitchFormationView extends StatelessWidget {
  final List<LineupPlayer> players;
  final String? formation;

  // 📝 HINT AR: التعيين التفاعلي (بند 12): عند true تُملأ خانات الخطة بترتيب
  // [players] (players[i] → الخانة i) بدل التوزيع حسب المركز. مع [onSlotTap]
  // يصبح كل خانة قابلة للنقر (لاختيار لاعبها) — يُستخدم في شاشة بناء التشكيلة.
  final bool bySlotOrder;
  final void Function(int slotIndex)? onSlotTap;

  const PitchFormationView({
    super.key,
    required this.players,
    this.formation,
    this.bySlotOrder = false,
    this.onSlotTap,
  });

  static const _gk = 'حارس';
  static const _def = 'مدافع';
  static const _fwd = 'مهاجم';

  @override
  Widget build(BuildContext context) {
    final placed = _placeChips();
    return AspectRatio(
      aspectRatio: 0.66, // عمودي ~ 2:3
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RotatedBox(
              quarterTurns: 1,
              child: Image.asset('assets/images/pitch.jpg', fit: BoxFit.cover),
            ),
            Container(color: Colors.black.withValues(alpha: 0.08)),
            if (players.isEmpty && onSlotTap == null)
              Center(
                child: Text(AppLocalizations.of(context)!.noFormationSet,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            for (final c in placed)
              Align(
                alignment: Alignment(c.x * 2 - 1, c.y * 2 - 1),
                child: onSlotTap != null
                    ? GestureDetector(
                        onTap: () => onSlotTap!(c.index),
                        child: _PlayerChip(player: c.player, line: c.line),
                      )
                    : _PlayerChip(player: c.player, line: c.line),
              ),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: يحسب موقع كل لاعب: إمّا على خانات الخطة الثابتة أو ترتيب تلقائي.
  List<({double x, double y, LineupPlayer? player, String line, int index})>
      _placeChips() {
    final gk = players.where((p) => p.position == _gk).toList();
    final def = players.where((p) => p.position == _def).toList();
    final fwd = players.where((p) => p.position == _fwd).toList();
    final mid = players
        .where((p) =>
            p.position != _gk && p.position != _def && p.position != _fwd)
        .toList();

    final result =
        <({double x, double y, LineupPlayer? player, String line, int index})>[];
    final fmt = formation;

    if (fmt != null && fmt.trim().isNotEmpty) {
      final slots = formationSlots(fmt);
      // التعيين التفاعلي: players[i] → الخانة i (بلا توزيع حسب المركز).
      if (bySlotOrder) {
        for (var i = 0; i < slots.length; i++) {
          final p = i < players.length ? players[i] : null;
          result.add((
            x: slots[i].x,
            y: slots[i].y,
            player: p,
            line: slots[i].line,
            index: i,
          ));
        }
        return result;
      }
      final queues = {
        'gk': Queue<LineupPlayer>.of(gk),
        'def': Queue<LineupPlayer>.of(def),
        'mid': Queue<LineupPlayer>.of(mid),
        'fwd': Queue<LineupPlayer>.of(fwd),
      };
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final q = queues[slot.line]!;
        final p = q.isNotEmpty ? q.removeFirst() : null;
        result.add(
            (x: slot.x, y: slot.y, player: p, line: slot.line, index: i));
      }
      return result;
    }

    // بلا خطة: ترتيب تلقائي حسب أعداد المراكز الفعلية.
    final lines = <({String line, double y, List<LineupPlayer> ps})>[
      (line: 'gk', y: 0.90, ps: gk),
      (line: 'def', y: 0.69, ps: def),
      (line: 'mid', y: 0.46, ps: mid),
      (line: 'fwd', y: 0.21, ps: fwd),
    ].where((l) => l.ps.isNotEmpty);
    var idx = 0;
    for (final l in lines) {
      final n = l.ps.length;
      for (var i = 0; i < n; i++) {
        result.add((
          x: (i + 1) / (n + 1),
          y: l.y,
          player: l.ps[i],
          line: l.line,
          index: idx++,
        ));
      }
    }
    return result;
  }
}

class _PlayerChip extends StatelessWidget {
  final LineupPlayer? player;
  final String line;
  const _PlayerChip({required this.player, required this.line});

  ImageProvider? get _image {
    final url = player?.photoUrl;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('assets/')
        ? AssetImage(url) as ImageProvider
        : CachedNetworkImageProvider(url);
  }

  String get _initial {
    final n = player?.name.trim() ?? '';
    return n.isEmpty ? '' : n.characters.first;
  }

  // 📝 HINT AR: اسم اللاعب، أو اسم المركز المُترجَم للخانة الفارغة (عرض فقط —
  // قيم المراكز في البيانات تبقى عربية للمقارنة).
  String _label(AppLocalizations l10n) {
    final n = player?.name.trim() ?? '';
    if (n.isNotEmpty) return n.split(RegExp(r'\s+')).first;
    switch (line) {
      case 'gk':
        return l10n.posGoalkeeper;
      case 'def':
        return l10n.posDefender;
      case 'fwd':
        return l10n.posForward;
      default:
        return l10n.posMidfielder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final empty = player == null;
    final img = _image;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: empty
                    ? Colors.white.withValues(alpha: 0.30)
                    : const Color(0xFFB9F6CA),
                backgroundImage: img,
                child: img == null
                    ? Text(_initial,
                        style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                            fontSize: 17))
                    : null,
              ),
            ),
            if (!empty && player!.shirtNumber != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text('${player!.shirtNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: empty ? 0.3 : 0.55),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _label(l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
