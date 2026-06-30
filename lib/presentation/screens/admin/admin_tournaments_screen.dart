import '../../../core/utils/image_helper.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: إدارة البطولات (للأدمن) — قائمة كل البطولات وتعديل (الاسم/صورة
/// البطولة/صورة الكأس/الجوائز/الراعي).
class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  late Future<List<TournamentModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<TournamentRepository>().getTournaments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البطولات'), centerTitle: true),
      body: FutureBuilder<List<TournamentModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text('لا توجد بطولات',
                  style: TextStyle(color: Colors.grey[600])),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) => _tile(list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(TournamentModel t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (t.logoUrl != null && t.logoUrl!.isNotEmpty)
              ? ImageHelper.getProvider(t.logoUrl!)
              : null,
          child: (t.logoUrl == null || t.logoUrl!.isEmpty)
              ? const Icon(Icons.emoji_events, color: Colors.grey)
              : null,
        ),
        title: Text(t.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(t.status == 'finished'
            ? 'منتهية • البطل: ${t.winnerTeamName ?? "—"}'
            : 'جارية • ${t.city}'),
        trailing: const Icon(Icons.edit),
        onTap: () => _openEditor(t),
      ),
    );
  }

  void _openEditor(TournamentModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TournamentEditor(
        tournament: t,
        repo: context.read<TournamentRepository>(),
        onSaved: () {
          if (mounted) setState(_reload);
        },
      ),
    );
  }
}

class _TournamentEditor extends StatefulWidget {
  final TournamentModel tournament;
  final TournamentRepository repo;
  final VoidCallback onSaved;
  const _TournamentEditor(
      {required this.tournament, required this.repo, required this.onSaved});

  @override
  State<_TournamentEditor> createState() => _TournamentEditorState();
}

class _TournamentEditorState extends State<_TournamentEditor> {
  late final TextEditingController _name;
  late final TextEditingController _prizes;
  late final TextEditingController _sponsor;
  late final TextEditingController _entryInfo;
  bool _isFree = true;
  File? _cover;
  File? _cup;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tournament.name);
    _prizes = TextEditingController(text: widget.tournament.prizes ?? '');
    _sponsor =
        TextEditingController(text: widget.tournament.sponsorName ?? '');
    _entryInfo =
        TextEditingController(text: widget.tournament.entryInfo ?? '');
    _isFree = widget.tournament.isFree;
  }

  @override
  void dispose() {
    _name.dispose();
    _prizes.dispose();
    _sponsor.dispose();
    _entryInfo.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isCup) async {
    final f = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200);
    if (f != null) {
      setState(() {
        if (isCup) {
          _cup = File(f.path);
        } else {
          _cover = File(f.path);
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = widget.tournament.id;
      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'prizes': _prizes.text.trim().isEmpty ? null : _prizes.text.trim(),
        'sponsorName':
            _sponsor.text.trim().isEmpty ? null : _sponsor.text.trim(),
        'isFree': _isFree,
        'entryInfo': _isFree || _entryInfo.text.trim().isEmpty
            ? null
            : _entryInfo.text.trim(),
      };
      if (_cover != null) {
        data['logoUrl'] =
            await widget.repo.uploadTournamentImage(id, _cover!, name: 'cover');
      }
      if (_cup != null) {
        data['cupImageUrl'] =
            await widget.repo.uploadTournamentImage(id, _cup!, name: 'cup');
      }
      await widget.repo.updateTournament(id, data);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر حفظ التعديلات');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
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
            const Text('تعديل البطولة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _imagePicker('صورة البطولة', _cover, t.logoUrl,
                      () => _pick(false)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _imagePicker('صورة الكأس', _cup, t.cupImageUrl,
                      () => _pick(true)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'اسم البطولة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prizes,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'الجوائز (اختياري)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sponsor,
              decoration: const InputDecoration(
                  labelText: 'اسم الراعي (اختياري)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            // 📝 HINT AR: مجانية/باشتراك (المرحلة 8) — الدخول المدفوع يُدار يدوياً.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('بطولة مجانية'),
              subtitle: Text(_isFree
                  ? 'مفتوحة لكل الفرق'
                  : 'باشتراك — يُضاف الفريق بعد الدفع'),
              value: _isFree,
              onChanged: (v) => setState(() => _isFree = v),
            ),
            if (!_isFree)
              TextField(
                controller: _entryInfo,
                decoration: const InputDecoration(
                    labelText: 'رسوم/تواصل الدخول (للعرض)',
                    border: OutlineInputBorder()),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker(
      String label, File? picked, String? existing, VoidCallback onTap) {
    DecorationImage? img;
    if (picked != null) {
      img = DecorationImage(image: FileImage(picked), fit: BoxFit.cover);
    } else if (existing != null && existing.isNotEmpty) {
      img = DecorationImage(
          image: ImageHelper.getProvider(existing), fit: BoxFit.cover);
    }
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: img,
            ),
            child: img == null
                ? const Center(
                    child: Icon(Icons.add_a_photo, color: Colors.grey))
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
