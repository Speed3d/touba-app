import '../../../core/utils/image_helper.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:share_plus/share_plus.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../core/utils/formations.dart';
import '../../widgets/core/pitch_formation_view.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/core/decorated_background.dart';

/// 📝 HINT AR: محرّر تشكيلة الفريق التفاعلي (يُفتح من «عرض/مشاركة» في إدارة الفريق).
/// الكابتن يختار الخطة (قالب ثابت أو مخصّصة)، يعيّن لاعبيه تفاعلياً على الملعب
/// (نقر دائرة → اختيار لاعب)، يحفظها (`teams.formation`+`teams.lineupSlots`)
/// ويشاركها كصورة. مماثل لتشكيلة البطولة لكن للخطة الأساسية للفريق.
class TeamFormationEditScreen extends StatefulWidget {
  final String teamId;
  final String teamName;
  final List<PlayerModel> players;
  final String? initialFormation;
  final List<String> initialSlots;

  const TeamFormationEditScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.players,
    this.initialFormation,
    this.initialSlots = const [],
  });

  @override
  State<TeamFormationEditScreen> createState() =>
      _TeamFormationEditScreenState();
}

class _TeamFormationEditScreenState extends State<TeamFormationEditScreen> {
  final _boundaryKey = GlobalKey();
  late String _formation;
  List<String?> _slots = [];
  bool _saving = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _formation = (widget.initialFormation != null &&
            widget.initialFormation!.isNotEmpty)
        ? widget.initialFormation!
        : defaultFormationFor(6);
    _resetSlots();
    // تعبئة الخانات من التعيين المحفوظ، وإلا من اللاعبين بالترتيب.
    if (widget.initialSlots.isNotEmpty) {
      for (var i = 0; i < widget.initialSlots.length && i < _slots.length; i++) {
        final id = widget.initialSlots[i];
        if (id.isNotEmpty && _playerById(id) != null) _slots[i] = id;
      }
    } else {
      _autoFill();
    }
  }

  void _resetSlots() {
    _slots = List<String?>.filled(formationTotal(_formation), null);
  }

  // 📝 HINT AR: تعبئة تلقائية أوّلية — الأساسيون أولاً ثم البقية، بترتيب الخانات.
  void _autoFill() {
    final ordered = [
      ...widget.players.where((p) => p.isStarter),
      ...widget.players.where((p) => !p.isStarter),
    ];
    for (var i = 0; i < _slots.length && i < ordered.length; i++) {
      _slots[i] = ordered[i].id;
    }
  }

  PlayerModel? _playerById(String? id) {
    if (id == null) return null;
    for (final p in widget.players) {
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
        : ImageHelper.getProvider(url);
  }

  LineupPlayer _toLineup(PlayerModel p) => LineupPlayer(
        playerId: p.id,
        name: p.name,
        photoUrl: p.photoUrl,
        position: p.position,
        shirtNumber: p.shirtNumber,
      );

  List<LineupPlayer> get _slotPlayers => _slots
      .map((id) => _playerById(id) != null
          ? _toLineup(_playerById(id)!)
          : const LineupPlayer(playerId: '', name: ''))
      .toList();

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
                child: Text(AppLocalizations.of(context)!.choosePlayerForSlotX((slotIndex + 1).toString()),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (current != null)
                ListTile(
                  leading: const Icon(Icons.remove_circle, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.removePlayerFromSlot),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _slots[slotIndex] = null);
                  },
                ),
              ...widget.players.map((p) {
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
                      (isElsewhere ? AppLocalizations.of(context)!.assignedToAnotherSlot : '')),
                  trailing: isHere
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: isElsewhere
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          setState(() => _slots[slotIndex] = p.id);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(AppLocalizations.of(context)!.chooseTeamFormation,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              for (final format in kPlayerFormats) ...[
                Text(AppLocalizations.of(context)!.playersCountX(format.toString()),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).colorScheme.primary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in kFormationOptions[format]!)
                      ChoiceChip(
                        label: Text(label),
                        selected: _formation == label,
                        onSelected: (_) {
                          Navigator.pop(ctx);
                          _applyFormation(label);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _customFormation();
                  },
                  icon: const Icon(Icons.dashboard_customize, size: 18),
                  label: Text(AppLocalizations.of(context)!.customFormation),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 HINT AR: خطة مخصّصة — الكابتن يحدّد عدد اللاعبين والمدافعين/الهجوم (حارس=1).
  void _customFormation() {
    final total = formationTotal(_formation);
    final outfield = total - 1;
    final def = (outfield / 3).floor().clamp(1, outfield);
    final fwd = (outfield / 3).floor().clamp(1, outfield - def);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: _CustomPlanBody(
          total: total,
          initialDef: def,
          initialFwd: fwd,
          onApply: (f) {
            Navigator.pop(ctx);
            _applyFormation(f);
          },
        ),
      ),
    );
  }

  void _applyFormation(String f) {
    setState(() {
      final old = List<String?>.from(_slots);
      _formation = f;
      _resetSlots();
      for (var i = 0; i < old.length && i < _slots.length; i++) {
        _slots[i] = old[i];
      }
    });
  }

  Future<void> _save() async {
    if (_slots.any((s) => s == null)) {
      ToobaSnackBar.warning(context, AppLocalizations.of(context)!.assignPlayerToEachSlot);
      return;
    }
    setState(() => _saving = true);
    final repo = context.read<TeamRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.setLineup(
          widget.teamId, _formation, _slots.whereType<String>().toList());
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.teamFormationSaved));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToSaveFormation));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final text = AppLocalizations.of(context)!.formationShareText(widget.teamName, _formation);
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final file = await File(
              '${Directory.systemTemp.path}/touba_lineup_${DateTime.now().millisecondsSinceEpoch}.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
          text: text);
    } catch (_) {
      if (!mounted) return;
      messenger
          .showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToShareFormation));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.teamFormation),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.share,
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share),
          ),
        ],
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                ),
              ),
              color: isDark ? const Color(0xFF161D27) : Colors.white,
              child: ListTile(
                leading: Icon(Icons.dashboard_customize,
                    color: theme.colorScheme.primary),
                title: Text(AppLocalizations.of(context)!.formationPlan,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(AppLocalizations.of(context)!.formationWithPlayersCount(_formation, formationTotal(_formation).toString())),
                trailing:
                    OutlinedButton(onPressed: _pickFormation, child: Text(AppLocalizations.of(context)!.changeBtn)),
              ),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.tapCircleToAssignPlayer,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])),
            const SizedBox(height: 8),
            // 📝 HINT AR: نلتقط هذا الجزء كصورة عند المشاركة.
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                padding: const EdgeInsets.all(8),
                child: PitchFormationView(
                  players: _slotPlayers,
                  formation: _formation,
                  bySlotOrder: true,
                  onSlotTap: _onSlotTap,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(AppLocalizations.of(context)!.share),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(AppLocalizations.of(context)!.saveBtn),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 📝 HINT AR: جسم «خطة مخصّصة» — عدد لاعبين (6/8/11) + المدافعون/الهجوم (حارس=1).
class _CustomPlanBody extends StatefulWidget {
  final int total;
  final int initialDef;
  final int initialFwd;
  final ValueChanged<String> onApply;
  const _CustomPlanBody({
    required this.total,
    required this.initialDef,
    required this.initialFwd,
    required this.onApply,
  });

  @override
  State<_CustomPlanBody> createState() => _CustomPlanBodyState();
}

class _CustomPlanBodyState extends State<_CustomPlanBody> {
  late int _total = widget.total;
  late int _def = widget.initialDef;
  late int _fwd = widget.initialFwd;

  void _clamp() {
    final outfield = _total - 1;
    if (_def < 1) _def = 1;
    if (_fwd < 1) _fwd = 1;
    if (_def + _fwd > outfield) _fwd = (outfield - _def).clamp(1, outfield);
    if (_def + _fwd > outfield) _def = (outfield - _fwd).clamp(1, outfield);
  }

  @override
  Widget build(BuildContext context) {
    _clamp();
    final mid = _total - 1 - _def - _fwd;
    Widget stepper(String label, int value, VoidCallback dec, VoidCallback inc) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                  onPressed: dec, icon: const Icon(Icons.remove_circle_outline)),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: inc, icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.customFormation,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context)!.numberOfPlayersLabel),
              for (final t in kPlayerFormats)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$t'),
                    selected: _total == t,
                    onSelected: (_) => setState(() => _total = t),
                  ),
                ),
            ],
          ),
          const Divider(),
          stepper(AppLocalizations.of(context)!.defendersCount, _def, () => setState(() => _def--),
              () => setState(() => _def++)),
          stepper(AppLocalizations.of(context)!.attackersCount, _fwd, () => setState(() => _fwd--),
              () => setState(() => _fwd++)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.midfieldAndTotalCount(mid.toString(), _total.toString()),
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: mid < 0
                  ? null
                  : () => widget.onApply('1-$_def-$mid-$_fwd'),
              child: Text(AppLocalizations.of(context)!.confirmFormation),
            ),
          ),
        ],
      ),
    );
  }
}
