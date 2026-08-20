import '../../../core/utils/image_helper.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import '../../cubits/team/team_manage_cubit.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/release_request_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../tournaments/tournament_details_screen.dart';
import 'team_management_screen.dart';
import '../players/player_detail_screen.dart';
import '../reports/submit_report_screen.dart';
import '../challenges/create_challenge_screen.dart';
import '../subscription/subscription_locked_sheet.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/core/decorated_background.dart';

/// 📝 HINT AR: صفحة الفريق — معلومات + إحصائيات + التشكيلة (سجلات اللاعبين).
class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen>
    with SingleTickerProviderStateMixin {
  // 📝 HINT AR: عضوية المُشاهد — فريقه الحالي (إن كان لاعباً مرتبطاً) لتحديد
  // أزرار الانضمام/الخروج (تدفّق: خروج إلزامي ثم انضمام).
  String? _myPlayerId;
  String? _myCurrentTeamId;
  String? _myCurrentTeamName;
  ReleaseRequestModel? _myRelease; // أحدث طلب خروج لي (إن وُجد)
  late final Future<List<TournamentModel>> _tournamentsFuture;
  // 📝 HINT AR: تبويبا «التشكيلة» و«النقاط حسب البطولة».
  late final TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TeamCubit>().fetchTeamDetails(widget.teamId);
    _resolveMyMembership();
    _tournamentsFuture =
        context.read<TournamentRepository>().getTournamentsByTeam(widget.teamId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _resolveMyMembership() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    final user = auth.user;
    if (user.linkedPlayerId == null || user.linkedPlayerId!.isEmpty) return;
    final playerRepo = context.read<PlayerRepository>();
    final teamRepo = context.read<TeamRepository>();
    try {
      final player = await playerRepo.getPlayerById(user.linkedPlayerId!);
      String? teamName;
      ReleaseRequestModel? release;
      if (player.currentTeamId.isNotEmpty) {
        try {
          final t = await teamRepo.getTeamById(player.currentTeamId);
          teamName = t.name;
        } catch (_) {}
        try {
          release = await teamRepo.getMyLatestReleaseRequest(player.id);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _myPlayerId = player.id;
        _myCurrentTeamId = player.currentTeamId;
        _myCurrentTeamName = teamName;
        _myRelease = release;
      });
    } catch (_) {}
  }

  Future<void> _escalateRelease() async {
    if (_myRelease == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final teamRepo = context.read<TeamRepository>();
    try {
      await teamRepo.escalateReleaseRequest(_myRelease!.id);
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          AppLocalizations.of(context)!.yourRequestEscalatedSoonReviewed));
      setState(() => _myRelease = null);
      _resolveMyMembership();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToEscalate));
    }
  }

  // 📝 HINT AR: تأكيد كلمة المرور (إعادة مصادقة Firebase) — للتأكد أن صاحب الحساب
  // هو من يطلب الخروج فعلاً (بند 15). يُعيد true عند نجاح المصادقة.
  Future<bool> _confirmPassword() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null || fbUser.email == null || fbUser.email!.isEmpty) {
      return false;
    }
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmPasswordTitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.confirmPasswordToExitDesc),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.passwordLabel, border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.confirm)),
        ],
      ),
    );
    if (ok != true || controller.text.isEmpty) return false;
    try {
      final cred = EmailAuthProvider.credential(
          email: fbUser.email!, password: controller.text);
      await fbUser.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.incorrectPassword);
      return false;
    } catch (_) {
      if (mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.failedToVerifyPassword);
      return false;
    }
  }

  // 📝 HINT AR: تحديث شعار الفريق (للكابتن من داخل صفحة الفريق) — اختيار مصدر،
  // رفع، تحديث الرابط، ثم إعادة تحميل التفاصيل.
  Future<void> _updateTeamLogo(String teamId) async {
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
    final picked = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 800);
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final teamRepo = context.read<TeamRepository>();
    final teamCubit = context.read<TeamCubit>();
    messenger.showSnackBar(ToobaSnackBar.buildInfo(AppLocalizations.of(context)!.updatingLogo));
    try {
      final url = await teamRepo.uploadTeamLogo(teamId, File(picked.path));
      await teamRepo.updateTeamLogo(teamId, url);
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.logoUpdatedSuccess));
      teamCubit.fetchTeamDetails(teamId);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToUpdateLogo));
    }
  }

  Future<void> _requestRelease(UserModel user) async {
    if (_myPlayerId == null ||
        _myCurrentTeamId == null ||
        _myCurrentTeamId!.isEmpty) {
      return;
    }
    // 📝 HINT AR: نلتقط المراجع قبل أي await (تفادي استخدام context عبر فجوة async).
    final messenger = ScaffoldMessenger.of(context);
    final teamRepo = context.read<TeamRepository>();
    // 📝 HINT AR: تأكيد كلمة المرور قبل إرسال الطلب (بند 15).
    if (!await _confirmPassword()) return;
    try {
      await teamRepo.requestRelease(
        playerId: _myPlayerId!,
        teamId: _myCurrentTeamId!,
        teamName: _myCurrentTeamName ?? '',
        userId: user.id,
        userName: user.name,
      );
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          AppLocalizations.of(context)!.exitRequestSentToCaptain));
    } catch (e) {
      messenger.showSnackBar(ToobaSnackBar.buildError(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = context.watch<AuthCubit>().state;
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    return BlocConsumer<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamActionSuccess) {
          ToobaSnackBar.success(context, state.message);
        } else if (state is TeamError) {
          ToobaSnackBar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is TeamLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (state is TeamDetailsLoaded && state.team.id == widget.teamId) {
          final team = state.team;
          final players = state.players;

          final isMyTeam =
              currentUser != null && team.captainId == currentUser.id;
          // 📝 HINT AR: «لاعب عادي» = ليس أدمن ولا كابتن. الأدمن/الكابتن لا
          // ينضمّون. حالات العضوية: عضو هنا / في فريق آخر / حرّ.
          final isPlayerUser = currentUser != null &&
              !isMyTeam &&
              !currentUser.isAdmin &&
              !currentUser.isCaptain;
          final amMemberHere =
              _myCurrentTeamId != null && _myCurrentTeamId == team.id;
          final amInAnotherTeam = _myCurrentTeamId != null &&
              _myCurrentTeamId!.isNotEmpty &&
              _myCurrentTeamId != team.id;

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(team.name),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              actions: [
                if (!isMyTeam)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'release') {
                        // 📝 HINT AR: طلب خروج العضو الحالي (مع تأكيد كلمة المرور).
                        if (currentUser != null) _requestRelease(currentUser);
                        return;
                      }
                      if (val != 'report') return;
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ToobaSnackBar.info(context, AppLocalizations.of(context)!.youMustLoginFirst);
                        return;
                      }
                      Navigator.push(
                        context,
                        ToobaRoute.to(SubmitReportScreen(
                            targetType: ReportTargetType.team,
                            targetId: team.id,
                            targetName: team.name,
                          ),
                        ),
                      );
                    },
                    itemBuilder: (_) => [
                      // 📝 HINT AR: «طلب الخروج» يظهر فقط للاعب العضو في هذا الفريق.
                      if (isPlayerUser && amMemberHere)
                        PopupMenuItem(
                          value: 'release',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.orange,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.exitTeamRequest,
                                  style: const TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, color: Colors.red,
                                size: 18),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.reportThisTeam,
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: DecoratedBackground(
              showOrbs: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'team_logo_${team.id}',
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color:
                                  isDark ? const Color(0xFF1A3050) : Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.colorScheme.primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: team.logoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: team.logoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (c, u, e) =>
                                          const Icon(Icons.shield, size: 60),
                                    )
                                  : Icon(Icons.shield,
                                      size: 60,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400]),
                            ),
                          ),
                        ),
                        // 📝 HINT AR: زر تغيير الشعار — للكابتن من داخل صفحة الفريق.
                        if (isMyTeam)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _updateTeamLogo(team.id),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    team.name,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        team.area != null && team.area!.isNotEmpty
                            ? '${team.city} • ${team.area}'
                            : team.city,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 📝 HINT AR: 4 كروت (لعب/فاز/خسر/تعادل) ليصحّ المجموع.
                  Row(
                    children: [
                      _statCard(context, AppLocalizations.of(context)!.playedCount, team.stats.played.toString()),
                      _statCard(context, AppLocalizations.of(context)!.winsCount, team.stats.wins.toString()),
                      _statCard(context, AppLocalizations.of(context)!.teamMatchesLost, team.stats.losses.toString()),
                      _statCard(context, AppLocalizations.of(context)!.teamMatchesDrawn, team.stats.draws.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 📝 HINT AR: معرض صور الفريق (إن وُجدت) — شريط أفقي.
                  if (team.photos.isNotEmpty) ...[
                    _teamPhotosStrip(team.photos),
                    const SizedBox(height: 24),
                  ],
                  // 📝 HINT AR: حالة اللاعب في هذا الفريق.
                  if (isPlayerUser && amMemberHere)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.youArePlayerInThisTeam,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  // اللاعب في فريق آخر: خروج إلزامي ثم انضمام.
                  if (isPlayerUser && amInAnotherTeam) ...[
                    if (_myRelease?.status == 'pending')
                      _releaseStatusBox(
                          AppLocalizations.of(context)!.exitRequestPendingCaptainReview,
                          Icons.hourglass_top,
                          Colors.blue)
                    else if (_myRelease?.status == 'rejected' &&
                        _myRelease?.escalated == true)
                      _releaseStatusBox(AppLocalizations.of(context)!.requestEscalatedPendingDecision,
                          Icons.gavel, Colors.purple)
                    else if (_myRelease?.status == 'rejected')
                      Column(
                        children: [
                          _releaseStatusBox(
                              AppLocalizations.of(context)!.captainRejectedYourRequest,
                              Icons.cancel,
                              Colors.red),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _escalateRelease,
                              icon: const Icon(Icons.gavel,
                                  color: Colors.purple),
                              label: Text(AppLocalizations.of(context)!.escalateRequestToAdmin,
                                  style: const TextStyle(color: Colors.purple)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.purple),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _requestRelease(currentUser),
                          icon: const Icon(Icons.logout, color: Colors.orange),
                          label: Text(
                              AppLocalizations.of(context)!.requestExitFromX(_myCurrentTeamName ?? AppLocalizations.of(context)!.myCurrentTeam),
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.orange)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // مُعطّل فعلياً: يجب الخروج أولاً.
                        onPressed: () => ToobaSnackBar.info(context,
                            AppLocalizations.of(context)!.mustExitCurrentTeamBeforeJoining),
                        icon: const Icon(Icons.person_add),
                        label: Text(AppLocalizations.of(context)!.requestToJoinTeam,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  // اللاعب الحرّ (بلا فريق): انضمام مباشر.
                  if (isPlayerUser && !amMemberHere && !amInAnotherTeam)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TeamCubit>().requestToJoinTeam(
                                team.id,
                                currentUser.id,
                                currentUser.name,
                              );
                        },
                        icon: const Icon(Icons.person_add),
                        label: Text(AppLocalizations.of(context)!.requestToJoinTeam,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (isMyTeam)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 📝 HINT AR: نوفّر TeamManageCubit محلياً لهذه الشاشة.
                          // عند الرجوع نُعيد تحميل تفاصيل الفريق ليظهر أي لاعب
                          // قُبل حديثاً (تحديث التشكيلة وعدّاد اللاعبين).
                          final teamCubit = context.read<TeamCubit>();
                          Navigator.push(
                            context,
                            ToobaRoute.to(BlocProvider(
                              create: (ctx) => TeamManageCubit(
                                ctx.read<TeamRepository>(),
                                ctx.read<PlayerRepository>(),
                                team.id,
                              )..load(),
                              child: const TeamManagementScreen(),
                            )),
                          ).then((_) => teamCubit.fetchTeamDetails(team.id));
                        },
                        icon: const Icon(Icons.settings),
                        label: Text(AppLocalizations.of(context)!.manageTeam,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  // 📝 HINT AR: زر «اطلب تحدي» — لكابتن يتصفّح فريقاً آخر (بند 17).
                  // مقفول بالاشتراك (التصفّح حرّ، الطلب يتطلّب اشتراكاً).
                  if (currentUser != null &&
                      currentUser.isCaptain &&
                      !isMyTeam) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!currentUser.isSubscriptionActive) {
                            SubscriptionLockedSheet.show(context,
                                feature: 'طلب التحدّي');
                            return;
                          }
                          Navigator.push(
                            context,
                            ToobaRoute.to(CreateChallengeScreen(
                                targetTeamName: team.name)),
                          );
                        },
                        icon: const Icon(Icons.sports_kabaddi),
                        label: Text(AppLocalizations.of(context)!.requestChallengeBtn,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (isPlayerUser || isMyTeam) const SizedBox(height: 24),
                  // ── تبويبان: التشكيلة + النقاط حسب البطولة ──
                  _sectionTabs(context, players, team.id),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(child: Text(AppLocalizations.of(context)!.loadingTeamDetails)),
        );
      },
    );
  }

  // 📝 HINT AR: كرت يحوي تبويبَي «التشكيلة» و«النقاط حسب البطولة».
  Widget _sectionTabs(
      BuildContext context, List<PlayerModel> players, String teamId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.rosterWithCount(players.length.toString())),
              Tab(text: AppLocalizations.of(context)!.pointsByTournament),
            ],
          ),
          // 📝 HINT AR: محتوى التبويب (داخل ScrollView، لذا نبني المحتوى مباشرة
          // بدل TabBarView الذي يحتاج ارتفاعاً محدوداً).
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _tabController.index == 0
                  ? _lineupTabContent(context, players)
                  : _tournamentsTabContent(context, teamId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineupTabContent(BuildContext context, List<PlayerModel> players) {
    if (players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(AppLocalizations.of(context)!.noPlayersRegisteredYet,
            style: TextStyle(color: Colors.grey[600])),
      );
    }
    return Column(
      children: players.map((p) => _playerCard(context, p)).toList(),
    );
  }

  // 📝 HINT AR: نقاط الفريق ومركزه في كل بطولة شارك بها (حساب لحظي من standings).
  Widget _tournamentsTabContent(BuildContext context, String teamId) {
    return FutureBuilder<List<TournamentModel>>(
      future: _tournamentsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final tournaments = snap.data ?? [];
        if (tournaments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppLocalizations.of(context)!.teamHasNotParticipatedInTournamentsYet,
                style: TextStyle(color: Colors.grey[600])),
          );
        }
        return Column(
          children: tournaments
              .map((t) => _tournamentRow(context, t, teamId))
              .toList(),
        );
      },
    );
  }

  Widget _tournamentRow(
      BuildContext context, TournamentModel t, String teamId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // مركز الفريق ونقاطه من standings (مفروزة مسبقاً من CF).
    int? rank;
    int? points;
    for (var i = 0; i < t.standings.length; i++) {
      final s = Map<String, dynamic>.from(t.standings[i]);
      if (s['teamId'] == teamId) {
        rank = i + 1;
        points = s['points'] ?? 0;
        break;
      }
    }
    final isChampion = t.status == 'finished' && t.winnerTeamId == teamId;

    return GestureDetector(
      onTap: () => _openTournament(context, t.id),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isChampion
                ? Colors.amber
                : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // المركز
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _rankColor(rank).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: isChampion
                ? const Icon(Icons.emoji_events,
                    color: Colors.amber, size: 22)
                : Text(rank != null ? '#$rank' : '—',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _rankColor(rank))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  t.status == 'finished' ? AppLocalizations.of(context)!.tournamentFinishedStatus : AppLocalizations.of(context)!.tournamentLiveStatus,
                  style: TextStyle(
                      fontSize: 12,
                      color: t.status == 'finished'
                          ? Colors.grey
                          : Colors.green),
                ),
              ],
            ),
          ),
          // النقاط
          Column(
            children: [
              Text(points != null ? '$points' : '—',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
              Text(AppLocalizations.of(context)!.pointSingle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // 📝 HINT AR: فتح تفاصيل البطولة (بـ TournamentCubit محلّي).
  void _openTournament(BuildContext context, String tournamentId) {
    Navigator.push(
      context,
      ToobaRoute.to(BlocProvider(
        create: (ctx) => TournamentCubit(
          ctx.read<TournamentRepository>(),
          ctx.read<MatchRepository>(),
          ctx.read<TeamRepository>(),
        )..fetchDetails(tournamentId),
        child: TournamentDetailsScreen(tournamentId: tournamentId),
      )),
    );
  }

  Color _rankColor(int? rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.blueGrey;
    if (rank == 3) return Colors.brown;
    return Colors.grey;
  }

  // 📝 HINT AR: شريط أفقي لصور الفريق (cache-first).
  Widget _teamPhotosStrip(List<String> photos) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: photos[i],
            width: 150,
            height: 110,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(
                width: 150, color: Colors.grey.shade200),
            errorWidget: (c, u, e) => Container(
                width: 150,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported,
                    color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _releaseStatusBox(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: كارت إحصاء قابل للتمدّد (Expanded) ليتّسع 4 كروت في الصف.
  Widget _statCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _playerCard(BuildContext context, PlayerModel player) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ImageProvider? imageProvider;
    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      if (player.photoUrl!.startsWith('assets/')) {
        imageProvider = AssetImage(player.photoUrl!);
      } else {
        imageProvider = ImageHelper.getProvider(player.photoUrl!);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          ToobaRoute.to(PlayerDetailScreen(player: player)),
        ),
        leading: CircleAvatar(
          backgroundColor: isDark ? const Color(0xFF1A3050) : Colors.grey[200],
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Row(
          children: [
            Text(player.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (player.isClaimed) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 14, color: Colors.blue),
            ],
          ],
        ),
        subtitle: Text(player.position),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.shirtNumber != null) ...[
              Text('#${player.shirtNumber}',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(player.careerStats.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
