import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/match_model.dart';
import 'pitch_formation_view.dart';

/// 📝 HINT AR: شيت سفلي يعرض التشكيلة على الملعب + زر **مشاركة** يلتقط صورة
/// الملعب (RepaintBoundary → PNG) ويشاركها عبر share_plus. مشترك بين شاشة إدارة
/// الفريق وتفاصيل المباراة.
class FormationShareSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<LineupPlayer> players;
  final String? formation;
  const FormationShareSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.players,
    this.formation,
  });

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<LineupPlayer> players,
    String? formation,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FormationShareSheet(
        title: title,
        subtitle: subtitle,
        players: players,
        formation: formation,
      ),
    );
  }

  @override
  State<FormationShareSheet> createState() => _FormationShareSheetState();
}

class _FormationShareSheetState extends State<FormationShareSheet> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      // 📝 HINT AR: نكتب الصورة لملف مؤقت ثم نشاركها بمساره (أوثق من fromData).
      final file = await File(
              '${Directory.systemTemp.path}/touba_lineup_${DateTime.now().millisecondsSinceEpoch}.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      final caption = widget.formation != null && widget.formation!.isNotEmpty
          ? '${widget.title} — خطة ${widget.formation}'
          : widget.title;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: caption,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّرت مشاركة التشكيلة')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          const SizedBox(height: 12),
          // 📝 HINT AR: نلتقط هذا الجزء كصورة عند المشاركة (خلفية معتمة لجمال الصورة).
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8),
              child: PitchFormationView(
                  players: widget.players, formation: widget.formation),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share, size: 18),
              label: const Text('مشاركة التشكيلة'),
            ),
          ),
        ],
      ),
    );
  }
}
