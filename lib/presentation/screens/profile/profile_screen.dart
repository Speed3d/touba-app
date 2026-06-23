import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/player_repository.dart';
import 'ready_images_selector_screen.dart';
import 'player_profile_edit_screen.dart';
import '../admin/admin_dashboard.dart';
import '../../../app/router/tooba_route.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: الملف الشخصي — شاشة تعديل مباشرة (صورة/اسم/هاتف) بلا أزرار علوية.
/// السياسات وحذف الحساب وتسجيل الخروج موحّدة في الإعدادات (لا تكرار هنا).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _loading = false;

  late TextEditingController _name;
  late TextEditingController _phone;
  File? _imageFile;
  String? _selectedAssetPath;
  String? _currentImage;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      _name = TextEditingController(text: state.user.name);
      _phone = TextEditingController(text: state.user.phone);
      _currentImage = state.user.profileImage;
    } else {
      _name = TextEditingController();
      _phone = TextEditingController();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final f = await _picker.pickImage(source: source, imageQuality: 70);
      if (f != null) {
        setState(() {
          _imageFile = File(f.path);
          _selectedAssetPath = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickReadyImage() async {
    final result = await Navigator.push<String>(
      context,
      ToobaRoute.to(const ReadyImagesSelectorScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedAssetPath = result;
        _imageFile = null;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('اختيار أفاتار جاهز'),
              onTap: () {
                Navigator.pop(ctx);
                _pickReadyImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final authCubit = context.read<AuthCubit>();
    final userRepo = context.read<UserRepository>();
    final playerRepo = context.read<PlayerRepository>();
    try {
      final state = authCubit.state;
      if (state is! AuthAuthenticated) throw Exception('المستخدم غير مسجّل');
      final user = state.user;
      String? finalImage = _currentImage;
      if (_selectedAssetPath != null) {
        finalImage = _selectedAssetPath; // أفاتار جاهز (لا رفع)
      } else if (_imageFile != null) {
        finalImage = await userRepo.uploadProfileImage(user.id, _imageFile!);
      }

      final updated = user.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        profileImage: finalImage,
      );
      await authCubit.updateProfile(updated);

      // 📝 HINT AR: نشر الصورة — لو الحساب مرتبط بسجل لاعب نحدّث صورته أيضاً
      // فتنعكس في بطاقة اللاعب وتشكيلة الفريق (عبر syncRosterSummary).
      if (user.linkedPlayerId != null &&
          user.linkedPlayerId!.isNotEmpty &&
          finalImage != null &&
          finalImage.isNotEmpty) {
        try {
          await playerRepo.setPhoto(user.linkedPlayerId!, finalImage);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _currentImage = finalImage;
          _imageFile = null;
          _selectedAssetPath = null;
        });
        ToobaSnackBar.success(context, 'تم تحديث بياناتك بنجاح');
      }
    } catch (e) {
      if (mounted) ToobaSnackBar.error(context, 'تعذّر تحديث البيانات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AuthCubit>().state;

    if (state is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: const Center(child: Text('سجّل الدخول لعرض ملفك')),
      );
    }
    final user = state.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatar(theme),
                const SizedBox(height: 8),
                Center(
                  child: Text(_roleLabel(user.role),
                      style: TextStyle(color: theme.colorScheme.primary)),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                  validator: (v) => v == null || v.length < 10
                      ? 'رقم الهاتف غير صالح'
                      : null,
                ),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.email,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التعديلات',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                // 📝 HINT AR: كود اللاعب الدائم — هويته الثابتة. يعطيه للكابتن ليضيفه.
                if (user.role == 'user' && user.playerCode != null) ...[
                  const SizedBox(height: 24),
                  _playerCodeCard(context, isDark, user.playerCode!),
                ],
                if (user.linkedPlayerId != null) ...[
                  const SizedBox(height: 16),
                  // 📝 HINT AR: بطاقة تفتح تعديل تفاصيل اللاعب الرياضية (بند 14).
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        ToobaRoute.to(PlayerProfileEditScreen(
                            playerId: user.linkedPlayerId!)),
                      ),
                      leading: Icon(Icons.sports_soccer,
                          color: theme.colorScheme.primary),
                      title: const Text('تفاصيل اللاعب الرياضية',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'القدم المفضّلة • الطول • الوزن • العمر • نبذة • معرض الصور',
                          style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_left),
                    ),
                  ),
                ],

                // لوحة الأدمن (للأدمن فقط).
                if (user.isAdmin) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.purple.shade700,
                        Colors.deepPurple.shade900
                      ]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(context,
                            ToobaRoute.to(const AdminDashboard())),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('لوحة تحكم الإدارة',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    ImageProvider? provider;
    if (_imageFile != null) {
      provider = FileImage(_imageFile!);
    } else if (_selectedAssetPath != null) {
      provider = AssetImage(_selectedAssetPath!);
    } else if (_currentImage != null && _currentImage!.isNotEmpty) {
      provider = _currentImage!.startsWith('assets/')
          ? AssetImage(_currentImage!) as ImageProvider
          : NetworkImage(_currentImage!);
    }
    return GestureDetector(
      onTap: _showImageOptions,
      child: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: provider,
              child: provider == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: بطاقة كود اللاعب الدائم — يعرضه ليعطيه للكابتن (نسخ/مشاركة).
  Widget _playerCodeCard(BuildContext context, bool isDark, String code) {
    final theme = Theme.of(context);
    final state = context.read<AuthCubit>().state;
    final linked =
        state is AuthAuthenticated && state.user.linkedPlayerId != null;
    return _infoCard(isDark, [
      Row(
        children: [
          Icon(Icons.badge, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('كود لاعبك الدائم',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 4),
      const Text('أعطِ هذا الكود لكابتن الفريق ليضيفك إلى تشكيلته.',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: SelectableText(
          code,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ToobaSnackBar.info(context, 'تم نسخ الكود');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('نسخ'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Share.share('كود لاعبي في طوبة: $code'),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('مشاركة'),
            ),
          ),
        ],
      ),
      if (!linked) ...[
        const SizedBox(height: 8),
        Text(
          'بمجرّد أن يضيفك الكابتن بهذا الكود، يرتبط حسابك ببطاقة لاعبك تلقائياً.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    ]);
  }

  Widget _infoCard(bool isDark, List<Widget> children) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  String _roleLabel(String role) {
    switch (role) {
      case 'captain':
        return 'كابتن فريق';
      case 'admin':
        return 'مدير المنصة';
      default:
        return 'لاعب';
    }
  }
}
