import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/city_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: إنشاء بطولة دوري — اختيار الاسم والمدينة والفرق المشاركة، ثم
/// يولّد النظام جدول المباريات تلقائياً (TournamentCubit.createTournament).
class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _city;
  String _tournamentType = 'league';
  bool _isHomeAndAway = false;
  String _generationMode = 'full_tree';
  int _numberOfGroups = 2;
  int _playerFormat = 6; // 6/8/11 — عدد اللاعبين الأساسيين المطلوب
  bool _validating = false;
  File? _logoFile; // صورة البطولة (للكارت)
  DateTime? _startDate; // موعد بداية البطولة
  int _roundIntervalDays = 7; // الفاصل بين الجولات (افتراضي أسبوعي)
  final ImagePicker _picker = ImagePicker();
  final Set<String> _selected = {};
  List<TeamModel> _teams = [];
  bool _loadingTeams = true;
  List<UserModel> _referees = [];
  final Set<String> _selectedReferees = {};
  
  final LocationRepository _locationRepo = LocationRepository();

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teamRepo = context.read<TeamRepository>();
    final userRepo = context.read<UserRepository>();
    try {
      final teams = await teamRepo.getTeams();
      List<UserModel> referees = [];
      try {
        referees = await userRepo.getReferees();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _teams = teams;
          _referees = referees;
          _loadingTeams = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null) {
      _snack('يرجى اختيار المدينة');
      return;
    }
    if (_selected.length < 2) {
      _snack('اختر فريقين على الأقل');
      return;
    }
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final selectedTeams =
        _teams.where((t) => _selected.contains(t.id)).toList();

    // 📝 HINT AR: تحقّق أن كل فريق مختار يملك عدداً كافياً من اللاعبين الأساسيين
    // (≥ نظام البطولة 5/7/11). يُحمَّل لاعبو الفرق المختارة مرة واحدة عند الإرسال.
    final playerRepo = context.read<PlayerRepository>();
    setState(() => _validating = true);
    try {
      for (final team in selectedTeams) {
        final players = await playerRepo.getPlayersByTeam(team.id);
        final starters = players.where((p) => p.isStarter).length;
        if (starters < _playerFormat) {
          if (mounted) {
            _snack(
                'فريق «${team.name}» يملك $starters أساسيين فقط — المطلوب $_playerFormat');
          }
          return;
        }
      }
    } catch (_) {
      if (mounted) _snack('تعذّر التحقّق من تشكيلات الفرق');
      return;
    } finally {
      if (mounted) setState(() => _validating = false);
    }

    if (!mounted) return;
    context.read<TournamentCubit>().createTournament(
          name: _nameController.text.trim(),
          city: _city!,
          organizerUid: authState.user.id,
          teams: selectedTeams,
          type: _tournamentType,
          isHomeAndAway: _isHomeAndAway,
          generationMode: _generationMode,
          numberOfGroups: _tournamentType == 'groups' ? _numberOfGroups : null,
          playerFormat: _playerFormat,
          logoFile: _logoFile,
          startDate: _startDate,
          roundIntervalDays: _roundIntervalDays,
          referees: _referees
              .where((r) => _selectedReferees.contains(r.id))
              .toList(),
        );
  }

  void _snack(String msg) => ToobaSnackBar.warning(context, msg);

  // 📝 HINT AR: اختيار صورة البطولة (معرض/كاميرا).
  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
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
        ]),
      ),
    );
    if (source == null) return;
    final f = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 1200);
    if (f != null) setState(() => _logoFile = File(f.path));
  }

  // 📝 HINT AR: اختيار تاريخ ووقت بداية البطولة (يُجدول المباريات تلقائياً).
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      helpText: 'موعد بداية البطولة',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _startDate != null
          ? TimeOfDay.fromDateTime(_startDate!)
          : const TimeOfDay(hour: 18, minute: 0),
    );
    if (!mounted) return;
    setState(() {
      _startDate = DateTime(date.year, date.month, date.day,
          time?.hour ?? 18, time?.minute ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? Colors.grey[900] : Colors.grey[100];
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return BlocListener<TournamentCubit, TournamentState>(
      listener: (context, state) {
        if (state is TournamentsLoaded) {
          ToobaSnackBar.success(context, 'تم إنشاء البطولة وتوليد الجدول!');
          Navigator.pop(context);
        } else if (state is TournamentError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('إنشاء بطولة'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: _loadingTeams
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // صورة البطولة (تظهر في الكارت).
                        Center(
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: fill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.primary),
                                image: _logoFile != null
                                    ? DecorationImage(
                                        image: FileImage(_logoFile!),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _logoFile == null
                                  ? Icon(Icons.add_a_photo,
                                      color: theme.colorScheme.primary,
                                      size: 32)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text('صورة البطولة (اختياري)',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'اسم البطولة',
                            prefixIcon: const Icon(Icons.emoji_events),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'يرجى إدخال اسم البطولة'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // موعد البداية + الفاصل بين الجولات.
                        InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'موعد بداية البطولة (اختياري)',
                              prefixIcon: const Icon(Icons.event),
                              border: border,
                              filled: true,
                              fillColor: fill,
                            ),
                            child: Text(
                              _startDate == null
                                  ? 'يُجدول النظام المباريات تلقائياً'
                                  : DateFormat('EEE d MMM yyyy • HH:mm', 'ar')
                                      .format(_startDate!),
                              style: TextStyle(
                                  color: _startDate == null
                                      ? Colors.grey
                                      : null),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: _roundIntervalDays,
                          decoration: InputDecoration(
                            labelText: 'الفاصل بين الجولات',
                            prefixIcon: const Icon(Icons.repeat),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('يومياً')),
                            DropdownMenuItem(value: 3, child: Text('كل 3 أيام')),
                            DropdownMenuItem(value: 7, child: Text('أسبوعياً')),
                            DropdownMenuItem(value: 14, child: Text('كل أسبوعين')),
                          ],
                          onChanged: (v) =>
                              setState(() => _roundIntervalDays = v ?? 7),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<CityModel>>(
                          stream: _locationRepo.getCitiesStream(activeOnly: true),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final cities = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              initialValue: _city,
                              decoration: InputDecoration(
                                labelText: 'المدينة',
                                prefixIcon: const Icon(Icons.location_on),
                                border: border,
                                filled: true,
                                fillColor: fill,
                              ),
                              items: cities
                                  .map((c) => DropdownMenuItem(value: c.nameAr, child: Text(c.nameAr)))
                                  .toList(),
                              onChanged: (v) => setState(() => _city = v),
                              validator: (v) => v == null ? 'يرجى اختيار المدينة' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _tournamentType,
                          decoration: InputDecoration(
                            labelText: 'نظام البطولة',
                            prefixIcon: const Icon(Icons.account_tree),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'league', child: Text('دوري (League)')),
                            DropdownMenuItem(value: 'knockout', child: Text('خروج المغلوب (Knockout)')),
                            DropdownMenuItem(value: 'groups', child: Text('مجموعات (Groups)')),
                          ],
                          onChanged: (v) => setState(() => _tournamentType = v!),
                        ),
                        const SizedBox(height: 16),

                        // نظام عدد اللاعبين (5/7/11)
                        DropdownButtonFormField<int>(
                          initialValue: _playerFormat,
                          decoration: InputDecoration(
                            labelText: 'عدد اللاعبين الأساسيين',
                            prefixIcon: const Icon(Icons.groups),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          items: const [
                            DropdownMenuItem(value: 6, child: Text('سداسي (6 لاعبين)')),
                            DropdownMenuItem(value: 8, child: Text('ثماني (8 لاعبين)')),
                            DropdownMenuItem(value: 11, child: Text('11 لاعب')),
                          ],
                          onChanged: (v) =>
                              setState(() => _playerFormat = v ?? 6),
                        ),
                        const SizedBox(height: 16),

                        // خيارات إضافية بناءً على نوع البطولة
                        Card(
                          elevation: 0,
                          color: fill,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('نظام الذهاب والإياب'),
                                  subtitle: const Text('تُلعب كل مواجهة مرتين'),
                                  value: _isHomeAndAway,
                                  onChanged: (v) => setState(() => _isHomeAndAway = v),
                                ),
                                if (_tournamentType == 'knockout' || _tournamentType == 'groups')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _generationMode,
                                      decoration: const InputDecoration(labelText: 'طريقة توليد المباريات الإقصائية'),
                                      items: const [
                                        DropdownMenuItem(value: 'full_tree', child: Text('توليد كامل الشجرة مقدماً (TBD)')),
                                        DropdownMenuItem(value: 'round_by_round', child: Text('توليد جولة بجولة')),
                                      ],
                                      onChanged: (v) => setState(() => _generationMode = v!),
                                    ),
                                  ),
                                if (_tournamentType == 'groups')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: TextFormField(
                                      initialValue: _numberOfGroups.toString(),
                                      decoration: const InputDecoration(labelText: 'عدد المجموعات'),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(() => _numberOfGroups = int.tryParse(v) ?? 2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('الفرق المشاركة (${_selected.length})',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_teams.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                                'لا توجد فرق بعد — أنشئ فرقاً أولاً من تبويب الفرق',
                                style: TextStyle(color: Colors.grey[600])),
                          )
                        else
                          ..._teams.map((t) => CheckboxListTile(
                                value: _selected.contains(t.id),
                                title: Text(t.name),
                                subtitle: Text(t.city),
                                onChanged: (sel) => setState(() {
                                  if (sel == true) {
                                    _selected.add(t.id);
                                  } else {
                                    _selected.remove(t.id);
                                  }
                                }),
                              )),
                        const SizedBox(height: 24),
                        // اختيار الحكّام (توزيع عشوائي بلا تعارض زمني).
                        Text('الحكّام (${_selectedReferees.length})',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            'يوزّعهم النظام عشوائياً على المباريات دون تكرار حكم بنفس الموعد.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        if (_referees.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                                'لا يوجد حكّام — يمنح الأدمن صفة الحكم للمستخدمين',
                                style: TextStyle(color: Colors.grey[600])),
                          )
                        else
                          ..._referees.map((r) => CheckboxListTile(
                                value: _selectedReferees.contains(r.id),
                                title: Text(r.name),
                                subtitle: Text(r.phone),
                                secondary: const Icon(Icons.sports),
                                onChanged: (sel) => setState(() {
                                  if (sel == true) {
                                    _selectedReferees.add(r.id);
                                  } else {
                                    _selectedReferees.remove(r.id);
                                  }
                                }),
                              )),
                        const SizedBox(height: 24),
                        BlocBuilder<TournamentCubit, TournamentState>(
                          builder: (context, state) {
                            final loading =
                                state is TournamentLoading || _validating;
                            return ElevatedButton(
                              onPressed: loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('إنشاء البطولة وتوليد الجدول',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
