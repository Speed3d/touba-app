import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../cubits/tournament/tournament_state.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/city_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../widgets/core/decorated_background.dart';

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
  // 📝 HINT AR: الوجبة 7 — حسم تعادل الإقصائي + عدد المتأهّلين من كل مجموعة.
  String _tieBreakMode = 'extratime_penalties';
  int _qualifiersPerGroup = 2;
  int _playerFormat = 6; // 6/8/11 — عدد اللاعبين الأساسيين المطلوب
  bool _isFree = true; // بطولة مجانية أو باشتراك (المرحلة 8)
  final _entryInfoController = TextEditingController(); // رسوم/تواصل الدخول
  bool _validating = false;
  File? _logoFile; // صورة البطولة (للكارت)
  DateTime? _startDate; // موعد بداية البطولة
  int _roundIntervalDays = 7; // الفاصل بين الجولات (افتراضي أسبوعي)
  // 📝 HINT AR: نمط الجدولة — 'rounds' (فاصل بين الجولات) أو 'daily' (توقيت يومي
  // ثابت مع عدد مباريات/يوم). + إعدادات المباراة الحيّة (المدّة/الأشواط).
  String _scheduleMode = 'rounds';
  int _matchesPerDay = 1; // مباريات/يوم في النمط اليومي
  int _matchGapMinutes = 90; // الفاصل بين مباريات اليوم الواحد
  int _matchDuration = 45; // مدّة الشوط (30/45) — للمؤقّت الحيّ
  int _halvesCount = 2; // عدد الأشواط (1/2)
  final ImagePicker _picker = ImagePicker();
  final Set<String> _selected = {};
  List<TeamModel> _teams = [];
  final Map<String, String> _captainNames = {}; // teamId → اسم الكابتن
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
      // 📝 HINT AR: أسماء كباتن الفرق (قراءة مجمّعة واحدة) — تُعرض على كرت الفريق.
      final captains = <String, String>{};
      try {
        final byUid = await userRepo
            .getUsersByIds(teams.map((t) => t.captainId).toList());
        for (final t in teams) {
          final u = byUid[t.captainId];
          if (u != null) captains[t.id] = u.name;
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _teams = teams;
          _referees = referees;
          _captainNames
            ..clear()
            ..addAll(captains);
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
    _entryInfoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null) {
      _snack(AppLocalizations.of(context)!.pleaseSelectCity);
      return;
    }
    if (_selected.length < 2) {
      _snack(AppLocalizations.of(context)!.selectTwoTeamsAtLeast);
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
            _snack(AppLocalizations.of(context)!.teamHasNotEnoughStarters(
                team.name, starters.toString(), _playerFormat.toString()));
          }
          return;
        }
      }
    } catch (_) {
      if (mounted) _snack(AppLocalizations.of(context)!.failedToValidateTeamLineups);
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
          scheduleMode: _scheduleMode,
          matchesPerDay: _matchesPerDay,
          matchGapMinutes: _matchGapMinutes,
          matchDuration: _matchDuration,
          halvesCount: _halvesCount,
          isFree: _isFree,
          entryInfo: _isFree || _entryInfoController.text.trim().isEmpty
              ? null
              : _entryInfoController.text.trim(),
          tieBreakMode: _tieBreakMode,
          qualifiersPerGroup: _qualifiersPerGroup,
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
            title: Text(AppLocalizations.of(context)!.chooseFromGallery),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(AppLocalizations.of(context)!.takePhoto),
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
      helpText: AppLocalizations.of(context)!.tournamentStartDateHelp,
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
    final fill = isDark ? AppColors.surfaceDark : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
      ),
    );

    return BlocListener<TournamentCubit, TournamentState>(
      listener: (context, state) {
        if (state is TournamentsLoaded) {
          ToobaSnackBar.success(context, AppLocalizations.of(context)!.tournamentCreatedAndScheduleGenerated);
          Navigator.pop(context);
        } else if (state is TournamentError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.createTournamentTitle),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: DecoratedBackground(
          showOrbs: false,
          child: _loadingTeams
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                        Center(
                          child: Text(AppLocalizations.of(context)!.tournamentImageOptional,
                              style:
                                  const TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.tournamentNameInputLabel,
                            prefixIcon: const Icon(Icons.emoji_events),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? AppLocalizations.of(context)!.pleaseEnterTournamentName
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // موعد البداية + الفاصل بين الجولات.
                        InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.tournamentStartDateOptional,
                              prefixIcon: const Icon(Icons.event),
                              border: border,
                              filled: true,
                              fillColor: fill,
                            ),
                            child: Text(
                              _startDate == null
                                  ? AppLocalizations.of(context)!.systemWillScheduleMatches
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
                        // ── نمط الجدولة ──
                        DropdownButtonFormField<String>(
                          initialValue: _scheduleMode,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.schedulingMode,
                            prefixIcon: const Icon(Icons.event_repeat),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'rounds',
                                child: Text(AppLocalizations.of(context)!.intervalBetweenRounds)),
                            DropdownMenuItem(
                                value: 'daily',
                                child: Text(AppLocalizations.of(context)!.fixedDailyTime)),
                          ],
                          onChanged: (v) =>
                              setState(() => _scheduleMode = v ?? 'rounds'),
                        ),
                        const SizedBox(height: 16),
                        if (_scheduleMode == 'rounds')
                          DropdownButtonFormField<int>(
                            initialValue: _roundIntervalDays,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.roundsIntervalLabel,
                              prefixIcon: const Icon(Icons.repeat),
                              border: border,
                              filled: true,
                              fillColor: fill,
                            ),
                            items: [
                              DropdownMenuItem(value: 1, child: Text(AppLocalizations.of(context)!.daily)),
                              DropdownMenuItem(
                                  value: 3, child: Text(AppLocalizations.of(context)!.everyThreeDays)),
                              DropdownMenuItem(
                                  value: 7, child: Text(AppLocalizations.of(context)!.weekly)),
                              DropdownMenuItem(
                                  value: 14, child: Text(AppLocalizations.of(context)!.everyTwoWeeks)),
                            ],
                            onChanged: (v) =>
                                setState(() => _roundIntervalDays = v ?? 7),
                          )
                        else ...[
                          // 📝 HINT AR: التوقيت اليومي = وقت «موعد البداية»؛ تُوزَّع
                          // المباريات يوماً بيوم، وأكثر من مباراة/يوم بفاصل زمني.
                          DropdownButtonFormField<int>(
                            initialValue: _matchesPerDay,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.matchesPerDay,
                              prefixIcon: const Icon(Icons.today),
                              border: border,
                              filled: true,
                              fillColor: fill,
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: 1, child: Text(AppLocalizations.of(context)!.oneMatch)),
                              DropdownMenuItem(
                                  value: 2, child: Text(AppLocalizations.of(context)!.twoMatches)),
                              DropdownMenuItem(
                                  value: 3, child: Text(AppLocalizations.of(context)!.threeMatches)),
                            ],
                            onChanged: (v) =>
                                setState(() => _matchesPerDay = v ?? 1),
                          ),
                          if (_matchesPerDay > 1) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _matchGapMinutes,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.intervalBetweenDailyMatches,
                                prefixIcon: const Icon(Icons.timelapse),
                                border: border,
                                filled: true,
                                fillColor: fill,
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: 60, child: Text(AppLocalizations.of(context)!.oneHour)),
                                DropdownMenuItem(
                                    value: 90, child: Text(AppLocalizations.of(context)!.oneAndHalfHours)),
                                DropdownMenuItem(
                                    value: 120, child: Text(AppLocalizations.of(context)!.twoHours)),
                              ],
                              onChanged: (v) =>
                                  setState(() => _matchGapMinutes = v ?? 90),
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),
                        // ── إعدادات المباراة (المدّة/الأشواط) للمؤقّت الحيّ ──
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _matchDuration,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.halfDuration,
                                  border: border,
                                  filled: true,
                                  fillColor: fill,
                                ),
                                items: [
                                  DropdownMenuItem(
                                      value: 30, child: Text(AppLocalizations.of(context)!.thirtyMinutes)),
                                  DropdownMenuItem(
                                      value: 45, child: Text(AppLocalizations.of(context)!.fortyFiveMinutes)),
                                ],
                                onChanged: (v) =>
                                    setState(() => _matchDuration = v ?? 45),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _halvesCount,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.halvesCount,
                                  border: border,
                                  filled: true,
                                  fillColor: fill,
                                ),
                                items: [
                                  DropdownMenuItem(
                                      value: 1, child: Text(AppLocalizations.of(context)!.oneHalf)),
                                  DropdownMenuItem(
                                      value: 2, child: Text(AppLocalizations.of(context)!.twoHalves)),
                                ],
                                onChanged: (v) =>
                                    setState(() => _halvesCount = v ?? 2),
                              ),
                            ),
                          ],
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
                                labelText: AppLocalizations.of(context)!.cityLabel,
                                prefixIcon: const Icon(Icons.location_on),
                                border: border,
                                filled: true,
                                fillColor: fill,
                              ),
                              items: cities
                                  .map((c) => DropdownMenuItem(value: c.nameAr, child: Text(c.nameAr)))
                                  .toList(),
                              onChanged: (v) => setState(() => _city = v),
                              validator: (v) => v == null ? AppLocalizations.of(context)!.pleaseSelectCity : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _tournamentType,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.tournamentSystem,
                            prefixIcon: const Icon(Icons.account_tree),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          items: [
                            DropdownMenuItem(value: 'league', child: Text(AppLocalizations.of(context)!.leagueSystem)),
                            DropdownMenuItem(value: 'knockout', child: Text(AppLocalizations.of(context)!.knockoutSystem)),
                            DropdownMenuItem(value: 'groups', child: Text(AppLocalizations.of(context)!.groupsSystem)),
                          ],
                          onChanged: (v) => setState(() => _tournamentType = v!),
                        ),
                        const SizedBox(height: 16),

                        // نظام عدد اللاعبين (5/7/11)
                        DropdownButtonFormField<int>(
                          initialValue: _playerFormat,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.startersCount,
                            prefixIcon: const Icon(Icons.groups),
                            border: border,
                            filled: true,
                            fillColor: fill,
                          ),
                          items: [
                            DropdownMenuItem(value: 6, child: Text(AppLocalizations.of(context)!.sixASide)),
                            DropdownMenuItem(value: 8, child: Text(AppLocalizations.of(context)!.eightASide)),
                            DropdownMenuItem(value: 11, child: Text(AppLocalizations.of(context)!.elevenASide)),
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
                                  title: Text(AppLocalizations.of(context)!.homeAndAwaySystem),
                                  subtitle: Text(AppLocalizations.of(context)!.homeAndAwaySubtitle),
                                  value: _isHomeAndAway,
                                  onChanged: (v) => setState(() => _isHomeAndAway = v),
                                ),
                                // 📝 HINT AR: مجانية/باشتراك (المرحلة 8) — الدخول المدفوع
                                // يُدار يدوياً من الأدمن (إضافة الفريق بعد الدفع).
                                SwitchListTile(
                                  title: Text(AppLocalizations.of(context)!.freeTournamentOption),
                                  subtitle: Text(_isFree
                                      ? AppLocalizations.of(context)!.freeTournamentSubtitle
                                      : AppLocalizations.of(context)!.paidTournamentSubtitle),
                                  value: _isFree,
                                  onChanged: (v) => setState(() => _isFree = v),
                                ),
                                if (!_isFree)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: TextField(
                                      controller: _entryInfoController,
                                      decoration: InputDecoration(
                                          labelText:
                                              AppLocalizations.of(context)!.entryFeesOrContact),
                                    ),
                                  ),
                                if (_tournamentType == 'knockout' || _tournamentType == 'groups')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _generationMode,
                                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.knockoutGenerationMethod),
                                      items: [
                                        DropdownMenuItem(value: 'full_tree', child: Text(AppLocalizations.of(context)!.generateFullTree)),
                                        DropdownMenuItem(value: 'round_by_round', child: Text(AppLocalizations.of(context)!.generateRoundByRound)),
                                      ],
                                      onChanged: (v) => setState(() => _generationMode = v!),
                                    ),
                                  ),
                                if (_tournamentType == 'groups')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: TextFormField(
                                      initialValue: _numberOfGroups.toString(),
                                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.groupsCountLabel),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(() => _numberOfGroups = int.tryParse(v) ?? 2),
                                    ),
                                  ),
                                // 📝 HINT AR: المتأهّلون من كل مجموعة (للمجموعات) —
                                // يُبنى منهم الإقصائي بالتزاوج القياسي (A1×B2...).
                                if (_tournamentType == 'groups')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _qualifiersPerGroup,
                                      decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)!.qualifiersPerGroup),
                                      items: [
                                        DropdownMenuItem(
                                            value: 1, child: Text(AppLocalizations.of(context)!.firstOnly)),
                                        DropdownMenuItem(
                                            value: 2,
                                            child: Text(AppLocalizations.of(context)!.firstAndSecond)),
                                        DropdownMenuItem(
                                            value: 3,
                                            child: Text(AppLocalizations.of(context)!.firstSecondThird)),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _qualifiersPerGroup = v ?? 2),
                                    ),
                                  ),
                                // 📝 HINT AR: حسم التعادل في الأدوار الإقصائية.
                                if (_tournamentType == 'knockout' ||
                                    _tournamentType == 'groups')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _tieBreakMode,
                                      decoration: InputDecoration(
                                          labelText:
                                              AppLocalizations.of(context)!.tieBreakRules),
                                      items: [
                                        DropdownMenuItem(
                                            value: 'extratime_penalties',
                                            child: Text(
                                                AppLocalizations.of(context)!.extraTimeThenPenalties)),
                                        DropdownMenuItem(
                                            value: 'penalties',
                                            child: Text(AppLocalizations.of(context)!.straightToPenalties)),
                                      ],
                                      onChanged: (v) => setState(() =>
                                          _tieBreakMode =
                                              v ?? 'extratime_penalties'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(AppLocalizations.of(context)!.participatingTeamsCountX(_selected.length.toString()),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_teams.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                                AppLocalizations.of(context)!.noTeamsYetCreateFirst,
                                style: TextStyle(color: Colors.grey[600])),
                          )
                        else
                          ..._teams.map((t) => CheckboxListTile(
                                value: _selected.contains(t.id),
                                title: Text(t.name),
                                // 📝 HINT AR: المدينة + اسم الكابتن (بند 8).
                                subtitle: Text(_captainNames[t.id] != null
                                    ? AppLocalizations.of(context)!.cityAndCaptainX(t.city, _captainNames[t.id]!)
                                    : t.city),
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
                        Text(AppLocalizations.of(context)!.refereesCountX(_selectedReferees.length.toString()),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            AppLocalizations.of(context)!.systemDistributesRefereesRandomly,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        if (_referees.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                                AppLocalizations.of(context)!.noRefereesAdminMustGrant,
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
                                    borderRadius: BorderRadius.circular(14)),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(AppLocalizations.of(context)!.createTournamentAndGenerateScheduleBtn,
                                      style: const TextStyle(
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
