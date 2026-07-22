import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: تعديل تفاصيل اللاعب الرياضية (لِلاعب صاحب السجل): القدم المفضّلة،
/// الطول، الوزن، تاريخ الميلاد (يُحسب منه العمر)، نبذة، ومعرض حتى 5 صور.
/// الإحصائيات (careerStats) تبقى من Cloud Functions حصراً — لا تُعدَّل هنا.
class PlayerProfileEditScreen extends StatefulWidget {
  final String playerId;
  const PlayerProfileEditScreen({super.key, required this.playerId});

  @override
  State<PlayerProfileEditScreen> createState() =>
      _PlayerProfileEditScreenState();
}

/// 📝 HINT AR: عنصر معرض — إمّا رابط محفوظ أو ملف محلّي جديد (يُرفع عند الحفظ).
class _GalleryItem {
  final String? url;
  final File? file;
  const _GalleryItem.url(this.url) : file = null;
  const _GalleryItem.file(this.file) : url = null;
  bool get isLocal => file != null;
}

class _PlayerProfileEditScreenState extends State<PlayerProfileEditScreen> {
  final _picker = ImagePicker();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _bio = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _preferredFoot; // right | left | both
  DateTime? _birthDate;
  final List<_GalleryItem> _gallery = [];

  static const _maxGallery = 5;
  late Map<String, String> _footLabels;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _footLabels = {
      'right': AppLocalizations.of(context)!.footRight,
      'left': AppLocalizations.of(context)!.footLeft,
      'both': AppLocalizations.of(context)!.footBoth,
    };
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _loadPlayer() async {
    try {
      final p =
          await context.read<PlayerRepository>().getPlayerById(widget.playerId);
      if (!mounted) return;
      setState(() {
        _preferredFoot = p.preferredFoot;
        _height.text = p.height?.toString() ?? '';
        _weight.text = p.weight?.toString() ?? '';
        _bio.text = p.bio ?? '';
        _birthDate = p.birthDate;
        _gallery
          ..clear()
          ..addAll(p.gallery.map((u) => _GalleryItem.url(u)));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToLoadPlayer);
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_gallery.length >= _maxGallery) return;
    try {
      final f = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70, maxWidth: 1000);
      if (f != null) {
        setState(() => _gallery.add(_GalleryItem.file(File(f.path))));
      }
    } catch (_) {}
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 70),
      lastDate: DateTime(now.year - 5),
      helpText: AppLocalizations.of(context)!.chooseBirthDate,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  int? get _age {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    var a = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      a--;
    }
    return a;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = context.read<PlayerRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 📝 HINT AR: نرفع الصور المحلّية الجديدة فقط، ثم نحفظ القائمة بالترتيب.
      final urls = <String>[];
      for (final item in _gallery) {
        if (item.isLocal) {
          urls.add(await repo.uploadGalleryImage(widget.playerId, item.file!));
        } else if (item.url != null) {
          urls.add(item.url!);
        }
      }
      await repo.setGallery(widget.playerId, urls);
      await repo.updatePersonalDetails(
        widget.playerId,
        preferredFoot: _preferredFoot,
        height: int.tryParse(_height.text.trim()),
        weight: int.tryParse(_weight.text.trim()),
        birthDate: _birthDate,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.detailsSaved));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToSaveDetails));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.playerDetails), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // القدم المفضّلة
                _label(AppLocalizations.of(context)!.preferredFoot),
                Wrap(
                  spacing: 8,
                  children: _footLabels.entries.map((e) {
                    final selected = _preferredFoot == e.key;
                    return ChoiceChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _preferredFoot = selected ? null : e.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // الطول والوزن
                Row(
                  children: [
                    Expanded(
                      child: _numberField(_height, AppLocalizations.of(context)!.heightCm, isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(_weight, AppLocalizations.of(context)!.weightKg, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // تاريخ الميلاد + العمر
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.birthDate,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    ),
                    child: Text(
                      _birthDate == null
                          ? AppLocalizations.of(context)!.notSpecified
                          : '${_birthDate!.year}/${_birthDate!.month}/${_birthDate!.day}'
                              '${_age != null ? '  •  ${AppLocalizations.of(context)!.ageYears(_age!)}' : ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // النبذة
                TextField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.bioTitle,
                    hintText: AppLocalizations.of(context)!.bioHint,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 8),
                // معرض الصور
                _label(AppLocalizations.of(context)!.yourGallery(_gallery.length, _maxGallery)),
                const SizedBox(height: 8),
                _galleryGrid(isDark),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.saveDetails,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      );

  Widget _numberField(
      TextEditingController c, String label, bool isDark) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
      ),
    );
  }

  Widget _galleryGrid(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._gallery.asMap().entries.map((e) {
          final item = e.value;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: item.isLocal
                      ? Image.file(item.file!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: item.url!,
                          fit: BoxFit.cover,
                          placeholder: (c, u) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (c, u, err) =>
                              Container(color: Colors.grey.shade200),
                        ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _gallery.removeAt(e.key)),
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
        if (_gallery.length < _maxGallery)
          GestureDetector(
            onTap: _pickGalleryImage,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Icon(Icons.add_a_photo_outlined,
                  color: Colors.grey, size: 28),
            ),
          ),
      ],
    );
  }
}
