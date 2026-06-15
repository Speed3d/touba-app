import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import 'ready_images_selector_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _bioController;

  String? _position;
  String? _preferredFoot;
  
  File? _imageFile;
  String? _selectedAssetPath;
  String? _currentProfileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController = TextEditingController(text: user.name);
      _heightController = TextEditingController(text: user.height?.toString());
      _weightController = TextEditingController(text: user.weight?.toString());
      _bioController = TextEditingController(text: user.bio);
      _position = user.position;
      _preferredFoot = user.preferredFoot;
      _currentProfileImage = user.profileImage;
    } else {
      _nameController = TextEditingController();
      _heightController = TextEditingController();
      _weightController = TextEditingController();
      _bioController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _selectedAssetPath = null; // Clear asset selection
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickReadyImage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ReadyImagesSelectorScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedAssetPath = result;
        _imageFile = null; // Clear local file selection
      });
    }
  }

  void _showImagePickerOptions() {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) throw Exception('المستخدم غير مسجل');
      
      final user = authState.user;
      String? finalImageUrl = _currentProfileImage;

      // Upload logic
      if (_selectedAssetPath != null) {
        finalImageUrl = _selectedAssetPath;
      } else if (_imageFile != null) {
        final repo = context.read<UserRepository>();
        finalImageUrl = await repo.uploadProfileImage(user.id, _imageFile!);
      }

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        height: int.tryParse(_heightController.text.trim()),
        weight: int.tryParse(_weightController.text.trim()),
        bio: _bioController.text.trim(),
        position: _position,
        preferredFoot: _preferredFoot,
        profileImage: finalImageUrl,
      );

      await context.read<AuthCubit>().updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_selectedAssetPath != null) {
      imageProvider = AssetImage(_selectedAssetPath!);
    } else if (_currentProfileImage != null && _currentProfileImage!.isNotEmpty) {
      if (_currentProfileImage!.startsWith('assets/')) {
        imageProvider = AssetImage(_currentProfileImage!);
      } else {
        imageProvider = NetworkImage(_currentProfileImage!);
      }
    }

    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatar(),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),

                // Position Dropdown
                DropdownButtonFormField<String>(
                  value: _position,
                  decoration: InputDecoration(
                    labelText: 'مركز اللعب',
                    prefixIcon: const Icon(Icons.sports_soccer),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'حارس مرمى', child: Text('حارس مرمى')),
                    DropdownMenuItem(value: 'مدافع', child: Text('مدافع')),
                    DropdownMenuItem(value: 'خط وسط', child: Text('خط وسط')),
                    DropdownMenuItem(value: 'مهاجم', child: Text('مهاجم')),
                  ],
                  onChanged: (val) => setState(() => _position = val),
                ),
                const SizedBox(height: 16),

                // Preferred Foot Dropdown
                DropdownButtonFormField<String>(
                  value: _preferredFoot,
                  decoration: InputDecoration(
                    labelText: 'القدم المفضلة',
                    prefixIcon: const Icon(Icons.do_not_step),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'يمنى', child: Text('يمنى')),
                    DropdownMenuItem(value: 'يسرى', child: Text('يسرى')),
                    DropdownMenuItem(value: 'كلاهما', child: Text('كلاهما')),
                  ],
                  onChanged: (val) => setState(() => _preferredFoot = val),
                ),
                const SizedBox(height: 16),

                // Height & Weight Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الطول (سم)',
                          prefixIcon: const Icon(Icons.height),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'الوزن (كجم)',
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نبذة عني',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'حفظ التعديلات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
