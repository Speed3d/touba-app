import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/city_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
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
  int _playerFormat = 7; // 5/7/11 — عدد اللاعبين الأساسيين المطلوب
  bool _validating = false;
  final Set<String> _selected = {};
  List<TeamModel> _teams = [];
  bool _loadingTeams = true;
  
  final LocationRepository _locationRepo = LocationRepository();

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await context.read<TeamRepository>().getTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
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
        );
  }

  void _snack(String msg) => ToobaSnackBar.warning(context, msg);

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
                            DropdownMenuItem(value: 5, child: Text('خماسي (5 لاعبين)')),
                            DropdownMenuItem(value: 7, child: Text('سباعي (7 لاعبين)')),
                            DropdownMenuItem(value: 11, child: Text('11 لاعب')),
                          ],
                          onChanged: (v) =>
                              setState(() => _playerFormat = v ?? 7),
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
