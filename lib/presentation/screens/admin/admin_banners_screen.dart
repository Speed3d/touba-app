import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: إدارة الإعلانات (للأدمن) — عرض/إضافة/تعديل/تفعيل/حذف البانرات.
class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  late Future<List<BannerModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<HomeRepository>().getAllBanners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإعلانات'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('إعلان جديد'),
      ),
      body: FutureBuilder<List<BannerModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final banners = snap.data ?? [];
          if (banners.isEmpty) {
            return Center(
              child: Text('لا توجد إعلانات — أضف أول إعلان',
                  style: TextStyle(color: Colors.grey[600])),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: banners.length,
              itemBuilder: (context, i) => _bannerTile(banners[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _bannerTile(BannerModel b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: b.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (c, u) =>
                  Container(height: 120, color: Colors.grey.shade200),
              errorWidget: (c, u, e) => Container(
                height: 120,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          ListTile(
            title: Text(b.title?.isNotEmpty == true ? b.title! : 'بدون عنوان',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الترتيب: ${b.order}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: b.isActive,
                  onChanged: (v) async {
                    await context
                        .read<HomeRepository>()
                        .setBannerActive(b.id, v);
                    if (mounted) setState(_reload);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _openEditor(banner: b),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _confirmDelete(b),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BannerModel b) async {
    final repo = context.read<HomeRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل تريد حذف هذا الإعلان نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repo.deleteBanner(b.id);
    if (mounted) setState(_reload);
  }

  void _openEditor({BannerModel? banner}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BannerEditor(
        banner: banner,
        repo: context.read<HomeRepository>(),
        onSaved: () {
          if (mounted) setState(_reload);
        },
      ),
    );
  }
}

/// نموذج إضافة/تعديل إعلان.
class _BannerEditor extends StatefulWidget {
  final BannerModel? banner;
  final HomeRepository repo;
  final VoidCallback onSaved;
  const _BannerEditor(
      {this.banner, required this.repo, required this.onSaved});

  @override
  State<_BannerEditor> createState() => _BannerEditorState();
}

class _BannerEditorState extends State<_BannerEditor> {
  final _title = TextEditingController();
  final _targetUrl = TextEditingController();
  final _order = TextEditingController(text: '0');
  File? _image;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    if (b != null) {
      _title.text = b.title ?? '';
      _targetUrl.text = b.targetUrl ?? '';
      _order.text = b.order.toString();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _targetUrl.dispose();
    _order.dispose();
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
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final f =
        await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1200);
    if (f != null) setState(() => _image = File(f.path));
  }

  Future<void> _save() async {
    final isNew = widget.banner == null;
    if (isNew && _image == null) {
      ToobaSnackBar.warning(context, 'اختر صورة الإعلان');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.banner?.id ?? const Uuid().v4();
      String imageUrl = widget.banner?.imageUrl ?? '';
      if (_image != null) {
        imageUrl = await widget.repo.uploadBannerImage(id, _image!);
      }
      final banner = BannerModel(
        id: id,
        imageUrl: imageUrl,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        targetUrl:
            _targetUrl.text.trim().isEmpty ? null : _targetUrl.text.trim(),
        isActive: widget.banner?.isActive ?? true,
        order: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: widget.banner?.createdAt,
      );
      await widget.repo.saveBanner(banner);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ToobaSnackBar.error(context, 'تعذّر حفظ الإعلان');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.banner;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(b == null ? 'إعلان جديد' : 'تعديل الإعلان',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: _image != null
                    ? DecorationImage(
                        image: FileImage(_image!), fit: BoxFit.cover)
                    : (b != null && b.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(b.imageUrl),
                            fit: BoxFit.cover)
                        : null),
              ),
              child: (_image == null &&
                      (b == null || b.imageUrl.isEmpty))
                  ? const Center(
                      child: Icon(Icons.add_a_photo,
                          color: Colors.grey, size: 32))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'العنوان (اختياري)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetUrl,
            decoration: const InputDecoration(
                labelText: 'رابط عند النقر (اختياري)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'ترتيب الظهور', border: OutlineInputBorder()),
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
    );
  }
}
