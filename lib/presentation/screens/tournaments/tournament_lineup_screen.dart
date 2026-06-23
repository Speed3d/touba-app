import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/tournament_lineup_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/tournament_lineup_repository.dart';
import '../../../core/utils/formations.dart';
import '../../widgets/core/pitch_formation_view.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: شاشة تشكيلة الكابتن في بطولة (بند 8 + 12). يختار الخطة (قالب ثابت
/// أو مخصّصة)، يعيّن لاعبيه تفاعلياً على الملعب (نقر دائرة → اختيار لاعب)، يحدّد
/// الاحتياط، ثم يرسلها لمراجعة المنظّم. يُعاد تحميل تشكيلته إن كانت موجودة.
class TournamentLineupScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final int playerFormat;
  final String teamId;
  final String teamName;

  const TournamentLineupScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.playerFormat,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TournamentLineupScreen> createState() => _TournamentLineupScreenState();
}

class _TournamentLineupScreenState extends State<TournamentLineupScreen> {
  late String _formation;
  List<String?> _slots = []; // playerId لكل خانة (بترتيب formationSlots)
  final Set<String> _subs = {};
  List<PlayerModel> _players = [];
  bool _loading = true;
  bool _submitting = false;
  String? _captainId;
  TournamentLineupModel? _existing;

  @override
  void initState() {
    super.initState();
    _formation = defaultFormationFor(widget.playerFormat);
    _resetSlots();
    _load();
  }

  void _resetSlots() {
    _slots = List<String?>.filled(formationTotal(_formation), null);
  }

  Future<void> _load() async {
    final playerRepo = context.read<PlayerRepository>();
    final lineupRepo = context.read<TournamentLineupRepository>();
    try {
      final players = await playerRepo.getPlayersByTeam(widget.teamId);
      final existing =
          await lineupRepo.getLineup(widget.tournamentId, widget.teamId);
      if (!mounted) return;
      setState(() {
        _players = players;
        _existing = existing;
        if (existing != null) {
          _formation = existing.formation ??
              defaultFormationFor(widget.playerFormat);
          _resetSlots();
          for (var i = 0;
              i < existing.starters.length && i < _slots.length;
              i++) {
            _slots[i] = existing.starters[i].playerId;
          }
          _subs.addAll(existing.subs.map((e) => e.playerId));
          _captainId = existing.captainId;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  PlayerModel? _playerById(String? id) {
    if (id == null) return null;
    for (final p in _players) {
      if (p.id == id) return p;
    }
    return null;
  }

  // 📝 HINT AR: صورة اللاعب (أصل جاهز أو رابط شبكة بكاش) لقائمة الاختيار.
  ImageProvider? _avatarImage(PlayerModel p) {
    final url = p.photoUrl;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('assets/')
        ? AssetImage(url) as ImageProvider
        : CachedNetworkImageProvider(url);
  }

  LineupPlayer _toLineup(PlayerModel p) => LineupPlayer(
        playerId: p.id,
        name: p.name,
        photoUrl: p.photoUrl,
        position: p.position,
        shirtNumber: p.shirtNumber,
      );

  // 📝 HINT AR: لاعبو الملعب الحاليون بترتيب الخانات (للعرض على الـ pitch).
  List<LineupPlayer> get _slotPlayers {
    return _slots.map((id) {
      final p = _playerById(id);
      return p != null
          ? _toLineup(p)
          : const LineupPlayer(playerId: '', name: '');
    }).toList();
  }

  void _onSlotTap(int slotIndex) {
    final placed = _slots.whereType<String>().toSet();
    final current = _slots[slotIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Text('اختر لاعب الخانة ${slotIndex + 1}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (current != null)
                ListTile(
                  leading: const Icon(Icons.remove_circle, color: Colors.red),
                  title: const Text('إزالة اللاعب من هذه الخانة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _slots[slotIndex] = null);
                  },
                ),
              ..._players.map((p) {
                final isHere = current == p.id;
                final isElsewhere = !isHere && placed.contains(p.id);
                final img = _avatarImage(p);
                return ListTile(
                  enabled: !isElsewhere,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: img,
                    child: img == null
                        ? Text(
                            p.name.isNotEmpty ? p.name.characters.first : '?')
                        : null,
                  ),
                  title: Text(p.name),
                  subtitle: Text(p.position +
                      (isElsewhere ? ' • معيّن في خانة أخرى' : '')),
                  trailing: isHere
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: isElsewhere
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          setState(() {
                            _slots[slotIndex] = p.id;
                            _subs.remove(p.id);
                          });
                        },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _pickFormation() {
    final options =
        kFormationOptions[widget.playerFormat] ?? [defaultFormationFor(widget.playerFormat)];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اختر الخطة (حارس-دفاع-وسط-هجوم)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in options)
                  ChoiceChip(
                    label: Text(f),
                    selected: _formation == f,
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      _applyFormation(f);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _customFormation();
              },
              icon: const Icon(Icons.dashboard_customize, size: 18),
              label: const Text('خطة مخصّصة'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: خطة مخصّصة — الكابتن يحدّد عدد المدافعين/الوسط/الهجوم (حارس=1)
  // بحيث يكون المجموع = عدد لاعبي النظام.
  void _customFormation() {
    final outfield = widget.playerFormat - 1;
    int def = (outfield / 3).floor().clamp(1, outfield);
    int fwd = (outfield / 3).floor().clamp(1, outfield - def);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          int mid = outfield - def - fwd;
          Widget stepper(String label, int value, VoidCallback dec,
              VoidCallback inc) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                        onPressed: dec,
                        icon: const Icon(Icons.remove_circle_outline)),
                    Text('$value',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: inc,
                        icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
              ],
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('خطة مخصّصة (الحارس ثابت)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  stepper('المدافعون', def, () {
                    if (def > 1) setS(() => def--);
                  }, () {
                    if (def + fwd < outfield) setS(() => def++);
                  }),
                  stepper('الهجوم', fwd, () {
                    if (fwd > 1) setS(() => fwd--);
                  }, () {
                    if (def + fwd < outfield) setS(() => fwd++);
                  }),
                  const Divider(),
                  Text('خط الوسط: $mid  •  المجموع: ${1 + def + mid + fwd}',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mid < 0
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _applyFormation('1-$def-$mid-$fwd');
                            },
                      child: const Text('اعتماد الخطة'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyFormation(String f) {
    setState(() {
      // نحاول الحفاظ على اللاعبين المعيّنين قدر الإمكان (نفس الترتيب).
      final old = List<String?>.from(_slots);
      _formation = f;
      _resetSlots();
      for (var i = 0; i < old.length && i < _slots.length; i++) {
        _slots[i] = old[i];
      }
    });
  }

  Future<void> _submit() async {
    if (_slots.any((s) => s == null)) {
      ToobaSnackBar.warning(context, 'عيّن لاعباً لكل خانة في التشكيلة');
      return;
    }
    if (_captainId == null) {
      ToobaSnackBar.error(context, 'تعذّر تحديد الكابتن');
      return;
    }
    setState(() => _submitting = true);
    final repo = context.read<TournamentLineupRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final starters = _slots
          .map((id) => _toLineup(_playerById(id)!))
          .toList();
      final subs = _subs
          .map((id) => _playerById(id))
          .whereType<PlayerModel>()
          .map(_toLineup)
          .toList();
      final lineup = TournamentLineupModel(
        id: TournamentLineupRepository.docId(widget.tournamentId, widget.teamId),
        tournamentId: widget.tournamentId,
        teamId: widget.teamId,
        teamName: widget.teamName,
        captainId: _captainId!,
        starters: starters,
        subs: subs,
        formation: _formation,
        status: 'pending',
      );
      await repo.submitLineup(lineup);
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess('أُرسلت التشكيلة لمراجعة المنظّم'));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر إرسال التشكيلة'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📝 HINT AR: الكابتن الحالي = منشئ هذه الجلسة. إن لم تكن هناك تشكيلة سابقة
    // نستنتج captainId من أول لاعب createdBy أو نتركه ليُملأ من سياق الفتح.
    _captainId ??= _players.isNotEmpty ? _players.first.createdByUid : null;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('تشكيلة البطولة'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${widget.teamName} • ${widget.tournamentName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_existing != null) ...[
                  const SizedBox(height: 8),
                  _statusBanner(_existing!),
                ],
                const SizedBox(height: 12),
                // الخطة + زر التغيير
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.dashboard_customize,
                        color: theme.colorScheme.primary),
                    title: const Text('الخطة',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_formation),
                    trailing: OutlinedButton(
                        onPressed: _pickFormation,
                        child: const Text('تغيير')),
                  ),
                ),
                const SizedBox(height: 8),
                Text('اضغط أي دائرة على الملعب لتعيين لاعبها',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                // الملعب التفاعلي
                PitchFormationView(
                  players: _slotPlayers,
                  formation: _formation,
                  bySlotOrder: true,
                  onSlotTap: _onSlotTap,
                ),
                const SizedBox(height: 20),
                // الاحتياط
                Text('الاحتياط (${_subs.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                _subsPicker(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: Text(_submitting
                        ? 'جارٍ الإرسال...'
                        : 'إرسال للمراجعة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statusBanner(TournamentLineupModel l) {
    final (color, icon, text) = l.isApproved
        ? (Colors.green, Icons.verified, 'تشكيلتك مقبولة')
        : l.isRejected
            ? (Colors.red, Icons.cancel,
                'رُفضت تشكيلتك${l.reviewNote != null ? " — ${l.reviewNote}" : ""}')
            : (Colors.blue, Icons.hourglass_top, 'تشكيلتك قيد المراجعة');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _subsPicker() {
    final placed = _slots.whereType<String>().toSet();
    final candidates =
        _players.where((p) => !placed.contains(p.id)).toList();
    if (candidates.isEmpty) {
      return Text('كل اللاعبين معيّنون كأساسيين',
          style: TextStyle(color: Colors.grey[600], fontSize: 13));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: candidates.map((p) {
        final selected = _subs.contains(p.id);
        return FilterChip(
          label: Text(p.name),
          selected: selected,
          onSelected: (_) => setState(() {
            selected ? _subs.remove(p.id) : _subs.add(p.id);
          }),
        );
      }).toList(),
    );
  }
}
