import '../../../core/utils/image_helper.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/news_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: إدارة الأخبار (للأدمن) — نشر/تعديل/حذف خبر (صورة + عنوان + مقال).
class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  late Future<List<NewsModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<HomeRepository>().getAllNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.adminNewsTitle), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newNewsBtn),
      ),
      body: FutureBuilder<List<NewsModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final news = snap.data ?? [];
          if (news.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noNews,
                  style: TextStyle(color: Colors.grey[600])),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: news.length,
              itemBuilder: (context, i) => _newsTile(news[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _newsTile(NewsModel n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: n.imageUrl != null && n.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: n.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) =>
                      const Icon(Icons.image_not_supported),
                ),
              )
            : const Icon(Icons.article, size: 40, color: Colors.grey),
        title: Text(n.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            AppLocalizations.of(context)!.newsStatsX(
              n.likeCount, n.shareCount,
              n.isPublished ? AppLocalizations.of(context)!.publishedLabel : AppLocalizations.of(context)!.hiddenLabel,
            ),
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _openEditor(news: n),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(n),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(NewsModel n) async {
    final repo = context.read<HomeRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNewsTitle),
        content: Text(AppLocalizations.of(context)!.deleteNewsBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repo.deleteNews(n.id);
    if (mounted) setState(_reload);
  }

  void _openEditor({NewsModel? news}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewsEditor(
        news: news,
        repo: context.read<HomeRepository>(),
        onSaved: () {
          if (mounted) setState(_reload);
        },
      ),
    );
  }
}

class _NewsEditor extends StatefulWidget {
  final NewsModel? news;
  final HomeRepository repo;
  final VoidCallback onSaved;
  const _NewsEditor({this.news, required this.repo, required this.onSaved});

  @override
  State<_NewsEditor> createState() => _NewsEditorState();
}

class _NewsEditorState extends State<_NewsEditor> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  File? _image;
  bool _published = true;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final n = widget.news;
    if (n != null) {
      _title.text = n.title;
      _body.text = n.body;
      _published = n.isPublished;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  // 📝 HINT AR: اختيار المصدر (معرض/كاميرا) عبر شيت سفلي ثم التقاط الصورة.
  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final f =
        await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1400);
    if (f != null) setState(() => _image = File(f.path));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ToobaSnackBar.warning(context, AppLocalizations.of(context)!.enterNewsTitle);
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.news?.id ?? const Uuid().v4();
      String? imageUrl = widget.news?.imageUrl;
      if (_image != null) {
        imageUrl = await widget.repo.uploadNewsImage(id, _image!);
      }
      final news = NewsModel(
        id: id,
        title: _title.text.trim(),
        body: _body.text.trim(),
        imageUrl: imageUrl,
        likes: widget.news?.likes ?? const [],
        shareCount: widget.news?.shareCount ?? 0,
        isPublished: _published,
        createdAt: widget.news?.createdAt,
      );
      await widget.repo.saveNews(news);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToSaveNews);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.news;
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
          Text(n == null ? AppLocalizations.of(context)!.newNews : AppLocalizations.of(context)!.editNews,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!), fit: BoxFit.cover)
                      : (n?.imageUrl != null && n!.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image:
                                  ImageHelper.getProvider(n.imageUrl!),
                              fit: BoxFit.cover)
                          : null),
                ),
                child: (_image == null &&
                        (n?.imageUrl == null || n!.imageUrl!.isEmpty))
                    ? const Center(
                        child: Icon(Icons.add_a_photo,
                            color: Colors.grey, size: 32))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newsTitleLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              maxLines: 5,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newsBodyLabel,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.publishedLabel),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
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
}
