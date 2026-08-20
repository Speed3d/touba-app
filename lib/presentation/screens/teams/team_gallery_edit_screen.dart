import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/core/decorated_background.dart';

/// 📝 HINT AR: تحرير معرض صور الفريق (حتى 5) — يديره الكابتن من إدارة الفريق
/// (بند 13). يضيف/يحذف الصور ويحفظها في `teams/{id}/gallery` + `teams.photos`.
class TeamGalleryEditScreen extends StatefulWidget {
  final String teamId;
  final List<String> initialPhotos;
  const TeamGalleryEditScreen({
    super.key,
    required this.teamId,
    required this.initialPhotos,
  });

  @override
  State<TeamGalleryEditScreen> createState() => _TeamGalleryEditScreenState();
}

class _GalleryItem {
  final String? url;
  final File? file;
  const _GalleryItem.url(this.url) : file = null;
  const _GalleryItem.file(this.file) : url = null;
  bool get isLocal => file != null;
}

class _TeamGalleryEditScreenState extends State<TeamGalleryEditScreen> {
  final _picker = ImagePicker();
  final List<_GalleryItem> _items = [];
  bool _saving = false;
  static const _max = 5;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.initialPhotos.map((u) => _GalleryItem.url(u)));
  }

  Future<void> _pick() async {
    if (_items.length >= _max) return;
    try {
      final f = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200);
      if (f != null) {
        setState(() => _items.add(_GalleryItem.file(File(f.path))));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = context.read<TeamRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final urls = <String>[];
      for (final item in _items) {
        if (item.isLocal) {
          urls.add(await repo.uploadTeamGalleryImage(widget.teamId, item.file!));
        } else if (item.url != null) {
          urls.add(item.url!);
        }
      }
      await repo.setTeamPhotos(widget.teamId, urls);
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.teamPhotosSaved));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToSavePhotos));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.teamPhotosTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(AppLocalizations.of(context)!.addUpToMaxPhotos(_max.toString(), _items.length.toString()),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._items.asMap().entries.map((e) {
                  final item = e.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 104,
                          height: 104,
                          child: item.isLocal
                              ? Image.file(item.file!, fit: BoxFit.cover)
                              : CachedNetworkImage(
                                  imageUrl: item.url!,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) =>
                                      Container(color: isDark ? AppColors.surfaceDark : Colors.grey.shade200),
                                  errorWidget: (c, u, err) =>
                                      Container(color: isDark ? AppColors.surfaceDark : Colors.grey.shade200),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _items.removeAt(e.key)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_items.length < _max)
                  GestureDetector(
                    onTap: _pick,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: Colors.grey, size: 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.savePhotosBtn,
                      style:
                          const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
