import '../../../core/utils/image_helper.dart';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: محرّر «الشروط والداعمون» (للمنظّم/الأدمن) — يضبط نصّ الشروط
/// والقوانين + لوكوات الداعمين + صور البانر المتحرك. تُحفظ كلها على مستند البطولة
/// (حقول عادية يسمح بها قاعدة tournaments للمنظّم/الأدمن). الصور تُرفع لحظة الإضافة.
class TournamentRulesEditor extends StatefulWidget {
  final TournamentModel tournament;
  final TournamentRepository repo;
  final VoidCallback onSaved;
  const TournamentRulesEditor({
    super.key,
    required this.tournament,
    required this.repo,
    required this.onSaved,
  });

  @override
  State<TournamentRulesEditor> createState() => _TournamentRulesEditorState();
}

class _TournamentRulesEditorState extends State<TournamentRulesEditor> {
  late final TextEditingController _rules;
  late List<Sponsor> _sponsors;
  late List<String> _banners;
  final _picker = ImagePicker();
  bool _saving = false;
  bool _busy = false; // أثناء رفع صورة

  @override
  void initState() {
    super.initState();
    _rules = TextEditingController(text: widget.tournament.rules ?? '');
    _sponsors = List<Sponsor>.from(widget.tournament.sponsors);
    _banners = List<String>.from(widget.tournament.adBanners);
  }

  @override
  void dispose() {
    _rules.dispose();
    super.dispose();
  }

  Future<File?> _pickImage() async {
    final f = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200);
    return f == null ? null : File(f.path);
  }

  // 📝 HINT AR: إضافة صورة بانر — تُرفع فوراً ويُخزَّن رابطها في القائمة.
  Future<void> _addBanner() async {
    final file = await _pickImage();
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final url = await widget.repo.uploadTournamentImage(
        widget.tournament.id,
        file,
        name: 'banner_${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() => _banners.add(url));
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToUploadBannerImage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 📝 HINT AR: إضافة داعم — اختيار اللوغو ثم إدخال الاسم ثم الرفع.
  Future<void> _addSponsor() async {
    final file = await _pickImage();
    if (file == null || !mounted) return;
    final name = await _promptName();
    if (name == null || name.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final url = await widget.repo.uploadTournamentImage(
        widget.tournament.id,
        file,
        name: 'sponsor_${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() => _sponsors.add(Sponsor(name: name.trim(), logoUrl: url)));
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToUploadSponsorLogo);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptName() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sponsorNameTitle),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.sponsorNameExample, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: Text(AppLocalizations.of(context)!.addBtn)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateTournament(widget.tournament.id, {
        'rules': _rules.text.trim().isEmpty ? null : _rules.text.trim(),
        'sponsors': _sponsors.map((s) => s.toJson()).toList(),
        'adBanners': _banners,
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToSaveChanges);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.editRulesAndSponsorsTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // ── الشروط والقوانين ──
            TextField(
              controller: _rules,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.rulesAndTermsLabel,
                hintText: AppLocalizations.of(context)!.writeRulesAndTermsHere,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            // ── البانرات المتحركة ──
            _sectionHeader(AppLocalizations.of(context)!.adBannersSection, Icons.view_carousel),
            const SizedBox(height: 8),
            _bannersGrid(),
            const SizedBox(height: 20),
            // ── الداعمون ──
            _sectionHeader(AppLocalizations.of(context)!.sponsorsSection, Icons.handshake),
            const SizedBox(height: 8),
            _sponsorsGrid(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_saving || _busy) ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.saveBtn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const Spacer(),
        if (_busy)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }

  Widget _bannersGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._banners.asMap().entries.map((e) => _thumb(
              imageUrl: e.value,
              onDelete: () => setState(() => _banners.removeAt(e.key)),
              width: 120,
              height: 70,
            )),
        _addTile(width: 120, height: 70, label: AppLocalizations.of(context)!.imageLabel, onTap: _addBanner),
      ],
    );
  }

  Widget _sponsorsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._sponsors.asMap().entries.map((e) => Column(
              children: [
                _thumb(
                  imageUrl: e.value.logoUrl,
                  onDelete: () => setState(() => _sponsors.removeAt(e.key)),
                  width: 80,
                  height: 80,
                  circle: true,
                ),
                SizedBox(
                  width: 80,
                  child: Text(e.value.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11)),
                ),
              ],
            )),
        _addTile(width: 80, height: 80, label: AppLocalizations.of(context)!.sponsorLabel, onTap: _addSponsor),
      ],
    );
  }

  Widget _thumb({
    required String imageUrl,
    required VoidCallback onDelete,
    required double width,
    required double height,
    bool circle = false,
  }) {
    final radius = BorderRadius.circular(circle ? 40 : 10);
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.grey.shade200,
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: ImageHelper.getProvider(imageUrl),
                    fit: BoxFit.cover)
                : null,
          ),
          child: imageUrl.isEmpty
              ? const Icon(Icons.image, color: Colors.grey)
              : null,
        ),
        Positioned(
          top: -6,
          left: -6,
          child: IconButton(
            icon: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _addTile({
    required double width,
    required double height,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: Colors.grey, size: 20),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
