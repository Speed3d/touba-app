import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: شاشة «طلب تحدٍّ ودّي» (بند 17). تُفتح من زر «اطلب تحدي» على صفحة
/// الفريق الشعبي (لكابتن مشترك). تنشر طلباً مفتوحاً باسم فريق الكابتن، ويمكن
/// لأي فريق (بما فيهم الفريق المستهدَف) التقدّم له. طلب مفتوح واحد لكل كابتن.
class CreateChallengeScreen extends StatefulWidget {
  final String? targetTeamName;
  const CreateChallengeScreen({super.key, this.targetTeamName});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _note = TextEditingController();
  DateTime? _date;
  TeamModel? _myTeam;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.targetTeamName != null) {
      _note.text = 'نطلب تحدّي فريق ${widget.targetTeamName}'; // Will override after build context is available
    }
    _resolveTeam();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _resolveTeam() async {
    final st = context.read<AuthCubit>().state;
    final uid = st is AuthAuthenticated ? st.user.id : null;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.loginFirstToProceed;
      });
      return;
    }
    try {
      final team = await context.read<TeamRepository>().getTeamByCaptain(uid);
      if (!mounted) return;
      setState(() {
        _myTeam = team;
        _loading = false;
        if (team == null) _error = AppLocalizations.of(context)!.youDoNotHaveATeamToRequestChallenge;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.failedToLoadYourTeamData;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (d == null || !mounted) return;
    final tm = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (tm == null) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, tm.hour, tm.minute));
  }

  Future<void> _submit() async {
    final t = _myTeam;
    if (t == null) return;
    final st = context.read<AuthCubit>().state;
    final uid = st is AuthAuthenticated ? st.user.id : null;
    if (uid == null) return;
    setState(() => _submitting = true);
    final repo = context.read<ChallengeRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 📝 HINT AR: طلب مفتوح واحد لكل كابتن (منع الإغراق).
      final existing = await repo.getMyOpenChallenge(uid);
      if (!mounted) return;
      if (existing != null) {
        messenger.showSnackBar(ToobaSnackBar.buildInfo(
            AppLocalizations.of(context)!.youAlreadyHaveOpenRequestEditIt));
        if (mounted) Navigator.pop(context);
        return;
      }
      final c = ChallengeModel(
        id: const Uuid().v4(),
        requesterTeamId: t.id,
        requesterTeamName: t.name,
        requesterCaptainId: uid,
        requesterLogo: t.logoUrl,
        city: t.city,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        matchDate: _date,
        status: 'open',
      );
      await repo.createChallenge(c);
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.challengeRequestPublished));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToPublishRequest));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.targetTeamName != null && _note.text.startsWith('نطلب تحدّي فريق')) {
       _note.text = AppLocalizations.of(context)!.requestChallengeWithTeam(widget.targetTeamName!);
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.requestChallengeTitle), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (widget.targetTeamName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(AppLocalizations.of(context)!.directedChallengeToTeam(widget.targetTeamName!),
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    Text(AppLocalizations.of(context)!.onBehalfOfTeam(_myTeam!.name, _myTeam!.city),
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.noteSuggestedPlaceTime,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_date == null
                          ? AppLocalizations.of(context)!.suggestedDateOptional
                          : DateFormat('EEE d MMM • HH:mm', 'ar').format(_date!)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(AppLocalizations.of(context)!.publishChallengeRequestBtn,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
    );
  }
}
