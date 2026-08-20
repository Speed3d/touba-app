import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_manage_cubit.dart';
import '../../cubits/team/team_manage_state.dart';
import '../../../data/models/player_model.dart';
import '../../../data/services/functions_service.dart';
import '../../../core/utils/formations.dart';
import 'add_player_screen.dart';
import 'team_gallery_edit_screen.dart';
import 'team_formation_edit_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: شاشة إدارة الفريق للكابتن — طلبات الانضمام + التشكيلة + دعوات الربط.
/// تتوقّع TeamManageCubit مُوفَّراً أعلاها (يُمرَّر عند التنقّل من صفحة الفريق).
class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.teamManagement),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: AppLocalizations.of(context)!.linkPlayerByCodeTitle,
            onPressed: () => _linkByCode(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddPlayer(context),
        icon: const Icon(Icons.person_add),
        label: Text(AppLocalizations.of(context)!.addPlayer),
      ),
      body: BlocConsumer<TeamManageCubit, TeamManageState>(
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          if (state is TeamManageActionSuccess) {
            ToobaSnackBar.success(context, _resolveTeamManageSuccess(l10n, state.message));
          } else if (state is TeamManageError) {
            ToobaSnackBar.error(context, _resolveTeamManageError(l10n, state.message));
          }
        },
        builder: (context, state) {
          if (state is TeamManageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TeamManageLoaded) {
            return _buildContent(context, state);
          }
          return Center(child: Text(AppLocalizations.of(context)!.loading));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TeamManageLoaded state) {
    final theme = Theme.of(context);
    final starters = state.players.where((p) => p.isStarter).toList();
    final subs = state.players.where((p) => !p.isStarter).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.requests.isNotEmpty) ...[
          Text(AppLocalizations.of(context)!.joinRequestsCountX(state.requests.length.toString()),
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...state.requests.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(r.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppLocalizations.of(context)!.joinRequestLabel),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () =>
                            context.read<TeamManageCubit>().acceptRequest(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () =>
                            context.read<TeamManageCubit>().rejectRequest(r),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
        if (state.releaseRequests.isNotEmpty) ...[
          Text(AppLocalizations.of(context)!.releaseRequestsCountX(state.releaseRequests.length.toString()),
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
          const SizedBox(height: 8),
          ...state.releaseRequests.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x22FF9800),
                    child: Icon(Icons.logout, color: Colors.orange),
                  ),
                  title: Text(r.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppLocalizations.of(context)!.requestsToLeaveTeam),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        tooltip: AppLocalizations.of(context)!.acceptLeave,
                        onPressed: () =>
                            context.read<TeamManageCubit>().acceptRelease(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: AppLocalizations.of(context)!.rejectBtn,
                        onPressed: () =>
                            context.read<TeamManageCubit>().rejectRelease(r),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],
        // ── خطة الفريق (التشكيلة الثابتة) ──
        _formationCard(context, state),
        const SizedBox(height: 12),
        // ── صور الفريق (معرض حتى 5) ──
        _galleryCard(context, state),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(AppLocalizations.of(context)!.rosterCountX(state.players.length.toString()),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (state.players.isNotEmpty)
              TextButton.icon(
                onPressed: () => _openFormationSheet(context, state),
                icon: const Icon(Icons.stadium, size: 18),
                label: Text(AppLocalizations.of(context)!.viewShare),
              ),
          ],
        ),
        Text(
            AppLocalizations.of(context)!.rosterManagementHint,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 12),
        if (state.players.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppLocalizations.of(context)!.noPlayersYetAddWithBtn,
                style: TextStyle(color: Colors.grey[600])),
          )
        else ...[
          _sectionLabel(context, AppLocalizations.of(context)!.starters, starters.length, Colors.green),
          if (starters.isEmpty) _miniHint(AppLocalizations.of(context)!.noStartersSelectFromSubs),
          ...starters.map((p) => _playerTile(context, p)),
          const SizedBox(height: 16),
          _sectionLabel(context, AppLocalizations.of(context)!.subs, subs.length, Colors.blueGrey),
          if (subs.isEmpty) _miniHint(AppLocalizations.of(context)!.noSubs),
          ...subs.map((p) => _playerTile(context, p)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // 📝 HINT AR: بطاقة خطة الفريق — تعرض الخطة الحالية وتفتح منتقي القوالب الثابتة.
  Widget _formationCard(BuildContext context, TeamManageLoaded state) {
    final theme = Theme.of(context);
    final fmt = state.team.formation;
    final hasFmt = fmt != null && fmt.isNotEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:
            Icon(Icons.dashboard_customize, color: theme.colorScheme.primary),
        title: Text(AppLocalizations.of(context)!.mainTeamFormation,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(hasFmt
            ? AppLocalizations.of(context)!.currentFormationX(fmt, formationTotal(fmt).toString())
            : AppLocalizations.of(context)!.notSetChooseCountAndFormation),
        trailing: OutlinedButton(
          onPressed: () => _pickFormation(context, state),
          child: Text(hasFmt ? AppLocalizations.of(context)!.changeBtn : AppLocalizations.of(context)!.selectBtn),
        ),
      ),
    );
  }

  // 📝 HINT AR: بطاقة معرض صور الفريق — تفتح شاشة التحرير (بند 13).
  Widget _galleryCard(BuildContext context, TeamManageLoaded state) {
    final theme = Theme.of(context);
    final count = state.team.photos.length;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.photo_library_outlined,
            color: theme.colorScheme.primary),
        title: Text(AppLocalizations.of(context)!.teamPhotosTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(count == 0
            ? AppLocalizations.of(context)!.noPhotosYetAddUpTo5
            : AppLocalizations.of(context)!.xOutOf5Photos(count.toString())),
        trailing: OutlinedButton(
          onPressed: () async {
            final cubit = context.read<TeamManageCubit>();
            final changed = await Navigator.push<bool>(
              context,
              ToobaRoute.to(TeamGalleryEditScreen(
                teamId: state.team.id,
                initialPhotos: state.team.photos,
              )),
            );
            if (changed == true) await cubit.load();
          },
          child: Text(count == 0 ? AppLocalizations.of(context)!.addBtn : AppLocalizations.of(context)!.editBtn),
        ),
      ),
    );
  }

  // 📝 HINT AR: منتقي القوالب الثابتة (6/8/11). الصيغة حارس-دفاع-وسط-هجوم.
  void _pickFormation(BuildContext context, TeamManageLoaded state) {
    final cubit = context.read<TeamManageCubit>();
    final current = state.team.formation;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(AppLocalizations.of(context)!.chooseTeamFormation,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(AppLocalizations.of(context)!.formationFormatHint,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              const SizedBox(height: 16),
              for (final format in kPlayerFormats) ...[
                Text(AppLocalizations.of(context)!.playersCountX(format.toString()),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).colorScheme.primary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in kFormationOptions[format]!)
                      ChoiceChip(
                        label: Text(label),
                        selected: current == label,
                        onSelected: (_) {
                          Navigator.pop(ctx);
                          cubit.setFormation(label);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 📝 HINT AR: محرّر التشكيلة التفاعلي (تعيين على الملعب + تغيير الخطة + مشاركة
  // + حفظ). عند الرجوع بعد الحفظ نُعيد تحميل بيانات الفريق.
  Future<void> _openFormationSheet(
      BuildContext context, TeamManageLoaded state) async {
    final cubit = context.read<TeamManageCubit>();
    final changed = await Navigator.push<bool>(
      context,
      ToobaRoute.to(TeamFormationEditScreen(
        teamId: state.team.id,
        teamName: state.team.name,
        players: state.players,
        initialFormation: state.team.formation,
        initialSlots: state.team.lineupSlots,
      )),
    );
    if (changed == true) await cubit.load();
  }

  Widget _sectionLabel(
      BuildContext context, String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Text('$title ($count)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _miniHint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 14),
        child:
            Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      );

  Widget _chip(
      {required VoidCallback onTap, required Color bg, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: child,
      ),
    );
  }

  // 📝 HINT AR: تعديل رقم قميص اللاعب (التحقق من التكرار في الكيوبت).
  void _editShirtNumber(BuildContext context, PlayerModel p) {
    final cubit = context.read<TeamManageCubit>();
    final controller =
        TextEditingController(text: p.shirtNumber?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.numberForX(p.name)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.shirtNumber, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
            onPressed: () {
              final txt = controller.text.trim();
              final number = txt.isEmpty ? null : int.tryParse(txt);
              Navigator.pop(ctx);
              cubit.setShirtNumber(p, number);
            },
            child: Text(AppLocalizations.of(context)!.saveBtn),
          ),
        ],
      ),
    );
  }

  Widget _playerTile(BuildContext context, PlayerModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (p.photoUrl != null && p.photoUrl!.isNotEmpty)
              ? (p.photoUrl!.startsWith('assets/')
                  ? AssetImage(p.photoUrl!) as ImageProvider
                  : NetworkImage(p.photoUrl!))
              : null,
          child: (p.photoUrl == null || p.photoUrl!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        title: Row(
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (p.isClaimed) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 14, color: Colors.blue),
            ],
          ],
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 📝 HINT AR: المركز قابل للضغط لتعديله (حارس/مدافع/وسط/مهاجم).
            _chip(
              onTap: () => _editPosition(context, p),
              bg: Colors.blueGrey.withValues(alpha: 0.12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.position, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 2),
                  Icon(Icons.edit, size: 11, color: Colors.grey[600]),
                ],
              ),
            ),
            // 📝 HINT AR: رقم القميص قابل للضغط لتعديله (مع منع التكرار).
            _chip(
              onTap: () => _editShirtNumber(context, p),
              bg: Colors.indigo.withValues(alpha: 0.10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.shirtNumber != null ? AppLocalizations.of(context)!.numberX(p.shirtNumber.toString()) : AppLocalizations.of(context)!.noNumber,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 2),
                  Icon(Icons.edit, size: 11, color: Colors.grey[600]),
                ],
              ),
            ),
            // 📝 HINT AR: شارة قابلة للضغط لنقل اللاعب بين أساسي/احتياط.
            InkWell(
              onTap: () => context.read<TeamManageCubit>().toggleStarter(p),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (p.isStarter ? Colors.green : Colors.grey)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.isStarter ? AppLocalizations.of(context)!.starter : AppLocalizations.of(context)!.sub,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: p.isStarter
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
        // 📝 HINT AR: الربط صار عبر كود اللاعب الدائم (زر «ربط لاعب بالكود» أعلى
        // الشاشة) — لا حاجة لزر دعوة لكل لاعب.
        // الربط صار عبر كود اللاعب الدائم
        trailing: p.isClaimed
            ? Text(AppLocalizations.of(context)!.linked, style: const TextStyle(color: Colors.blue))
            : Text(AppLocalizations.of(context)!.notLinked, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ),
    );
  }

  // 📝 HINT AR: تعديل مركز اللاعب عبر شيت سفلي.
  void _editPosition(BuildContext context, PlayerModel p) {
    const positions = ['حارس', 'مدافع', 'وسط', 'مهاجم'];
    final cubit = context.read<TeamManageCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context)!.positionForX(p.name),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...positions.map((pos) => ListTile(
                  leading: Icon(
                    p.position == pos
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  title: Text(pos),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (pos != p.position) cubit.setPosition(p, pos);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: ربط لاعب موجود بحساب عبر كوده الدائم (الهوية الدائمة).
  void _linkByCode(BuildContext context) {
    final controller = TextEditingController();
    final cubit = context.read<TeamManageCubit>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.linkPlayerByCodeTitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.enterPlayerCodeHint),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.exampleCode,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancelBtn)),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(ToobaSnackBar.buildInfo(AppLocalizations.of(context)!.linking));
              try {
                await FunctionsService()
                    .linkPlayerByCode(cubit.teamId, code);
                if (!context.mounted) return;
                messenger.showSnackBar(
                    ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.playerAddedToRoster));
                await Future.delayed(const Duration(milliseconds: 800));
                await cubit.load();
              } on FirebaseFunctionsException catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(ToobaSnackBar.buildError(
                    e.message ?? AppLocalizations.of(context)!.failedToLinkPlayer));
              } catch (_) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                    ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToLinkPlayer));
              }
            },
            child: Text(AppLocalizations.of(context)!.linkBtn),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddPlayer(BuildContext context) async {
    // 📝 HINT AR: نلتقط المراجع قبل await لتفادي استخدام BuildContext عبر فجوة async.
    final cubit = context.read<TeamManageCubit>();
    final authState = context.read<AuthCubit>().state;
    final captainId =
        authState is AuthAuthenticated ? authState.user.id : null;
    if (captainId == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      ToobaRoute.to(const AddPlayerScreen()),
    );
    if (result == null) return;
    await cubit.addPlayer(
      captainId: captainId,
      name: result['name'] as String,
      position: result['position'] as String,
      shirtNumber: result['shirtNumber'] as int?,
      preferredFoot: result['preferredFoot'] as String?,
    );
  }

  String _resolveTeamManageSuccess(AppLocalizations l10n, String raw) {
    switch (raw) {
      case 'تم حفظ خطة الفريق':
        return l10n.teamSuccessFormationSaved;
      case 'تم حفظ تشكيلة الفريق':
        return l10n.teamSuccessLineupSaved;
      case 'تم تحديث رقم اللاعب':
        return l10n.teamSuccessShirtNumberUpdated;
      case 'تم قبول الخروج وفكّ ارتباط اللاعب':
        return l10n.teamSuccessReleaseAccepted;
      case 'تم رفض طلب الخروج':
        return l10n.teamSuccessReleaseRejected;
      case 'تمت إضافة اللاعب للتشكيلة':
        return l10n.teamSuccessPlayerAdded;
      case 'تم قبول الطلب — سيُضاف اللاعب للتشكيلة تلقائياً':
        return l10n.teamSuccessJoinAccepted;
      case 'تم رفض الطلب':
        return l10n.teamSuccessJoinRejected;
      default:
        return raw;
    }
  }

  String _resolveTeamManageError(AppLocalizations l10n, String raw) {
    if (raw.contains('مستخدم من لاعب آخر') || raw.contains('مستخدم — اختر رقماً آخر')) {
      final match = RegExp(r'\d+').firstMatch(raw);
      final num = match?.group(0) ?? '';
      return l10n.teamErrorShirtNumberDuplicate(num);
    }
    if (raw.contains('أنت منضم لهذا الفريق بالفعل')) {
      return l10n.teamErrorAlreadyJoined;
    }
    if (raw.contains('لديك طلب معلّق لهذا الفريق بالفعل')) {
      return l10n.teamErrorPendingRequestExists;
    }
    if (raw.contains('لديك طلب خروج قيد المراجعة بالفعل')) {
      return l10n.teamErrorPendingReleaseExists;
    }
    if (raw.contains('الفريق غير موجود')) {
      return l10n.teamErrorTeamNotFound;
    }
    return raw.replaceFirst('Exception: ', '');
  }
}
