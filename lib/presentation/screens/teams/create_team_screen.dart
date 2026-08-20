import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/core/decorated_background.dart';

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
    'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كربلاء', 
    'كركوك', 'الأنبار', 'ديالى', 'بابل', 'ميسان', 'المثنى', 
    'ذي قار', 'القادسية', 'صلاح الدين', 'واسط', 'دهوك', 'السليمانية'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 600);
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
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.takePhoto),
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
        ToobaSnackBar.info(context, AppLocalizations.of(context)!.pleaseSelectCity);
        return;
      }

      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) {
        ToobaSnackBar.info(context, AppLocalizations.of(context)!.youMustLoginFirst);
        return;
      }

      context.read<TeamCubit>().createTeam(
            name: _nameController.text.trim(),
            city: _selectedCity!,
            area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
            captainId: authState.user.id,
            logoFile: _logoFile,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamActionSuccess) {
          ToobaSnackBar.success(context, state.message);
          Navigator.pop(context);
        } else if (state is TeamError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is TeamLoading;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.createTeamTitle),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: DecoratedBackground(
            showOrbs: false,
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
                                color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFF1F5F9),
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
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.teamLogoOptional,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Team Name
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.teamNameLabel,
                        prefixIcon: const Icon(Icons.sports_soccer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? AppLocalizations.of(context)!.pleaseEnterTeamName : null,
                    ),
                    const SizedBox(height: 16),

                    // City
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.cityOrGovernorate,
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
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
                        labelText: AppLocalizations.of(context)!.areaOptional,
                        hintText: AppLocalizations.of(context)!.areaExample,
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              AppLocalizations.of(context)!.createTeamBtn,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
