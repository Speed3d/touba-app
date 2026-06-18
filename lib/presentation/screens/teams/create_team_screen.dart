import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import '../../../core/utils/tooba_snack_bar.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  String? _selectedCity;
  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _iraqCities = [
    'بغداد', 'البصرة', 'الموصل', 'أربيل', 'النجف', 
    'كربلاء', 'كركوك', 'الأنبار', 'بابل', 'ذي قار'
  ]; // This can be expanded or fetched from a constant file later.

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCity == null) {
        ToobaSnackBar.warning(context, 'يرجى اختيار المحافظة');
        return;
      }
      
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        final area = _areaController.text.trim();
        context.read<TeamCubit>().createTeam(
          name: _nameController.text.trim(),
          city: _selectedCity!,
          area: area.isEmpty ? null : area,
          captainId: authState.user.id,
          logoFile: _logoFile,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamsLoaded) {
          // Because creating a team triggers fetchTeams() and then TeamsLoaded
          ToobaSnackBar.success(context, 'تم إنشاء الفريق بنجاح!');
          Navigator.pop(context);
        } else if (state is TeamError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تأسيس فريق جديد'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<TeamCubit, TeamState>(
          builder: (context, state) {
            final isLoading = state is TeamLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Picker
                      Center(
                        child: GestureDetector(
                          onTap: isLoading ? null : _showImagePickerOptions,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                  image: _logoFile != null
                                      ? DecorationImage(
                                          image: FileImage(_logoFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _logoFile == null
                                    ? Icon(
                                        Icons.shield,
                                        size: 60,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      )
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
                                  child: const Icon(Icons.add_a_photo, size: 20, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'شعار الفريق (اختياري)',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Team Name
                      TextFormField(
                        controller: _nameController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'اسم الفريق',
                          prefixIcon: const Icon(Icons.sports_soccer),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم الفريق' : null,
                      ),
                      const SizedBox(height: 16),

                      // City
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'المحافظة / المدينة',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        ),
                        items: _iraqCities.map((city) {
                          return DropdownMenuItem(value: city, child: Text(city));
                        }).toList(),
                        onChanged: isLoading ? null : (val) => setState(() => _selectedCity = val),
                      ),
                      const SizedBox(height: 16),

                      // Area / District
                      TextFormField(
                        controller: _areaController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'المنطقة (اختياري)',
                          hintText: 'مثال: حي الجامعة، الكرادة...',
                          prefixIcon: const Icon(Icons.map_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'تأسيس الفريق',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
