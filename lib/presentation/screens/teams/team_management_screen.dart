import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_manage_cubit.dart';
import '../../cubits/team/team_manage_state.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/services/functions_service.dart';
import '../../../core/utils/formations.dart';
import '../../widgets/core/formation_share_sheet.dart';
import 'add_player_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';

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
        title: const Text('إدارة الفريق'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'ربط لاعب بالكود',
            onPressed: () => _linkByCode(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddPlayer(context),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة لاعب'),
      ),
      body: BlocConsumer<TeamManageCubit, TeamManageState>(
        listener: (context, state) {
          if (state is TeamManageActionSuccess) {
            ToobaSnackBar.success(context, state.message);
          } else if (state is TeamManageError) {
            ToobaSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is TeamManageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TeamManageLoaded) {
            return _buildContent(context, state);
          }
          return const Center(child: Text('جارٍ التحميل...'));
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
          Text('طلبات الانضمام (${state.requests.length})',
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...state.requests.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(r.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('طلب انضمام'),
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
          Text('طلبات الخروج (${state.releaseRequests.length})',
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
                  subtitle: const Text('يطلب الخروج من الفريق'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        tooltip: 'قبول الخروج',
                        onPressed: () =>
                            context.read<TeamManageCubit>().acceptRelease(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'رفض',
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
        const SizedBox(height: 16),
        Row(
          children: [
            Text('التشكيلة (${state.players.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (state.players.isNotEmpty)
              TextButton.icon(
                onPressed: () => _openFormationSheet(context, state),
                icon: const Icon(Icons.stadium, size: 18),
                label: const Text('عرض/مشاركة'),
              ),
          ],
        ),
        Text(
            'اضغط شارة «أساسي/احتياط» لنقل اللاعب بين القسمين • اضغط «رقم» لتعديله',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 12),
        if (state.players.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('لا يوجد لاعبون بعد — أضِف لاعبيك بزر «إضافة لاعب»',
                style: TextStyle(color: Colors.grey[600])),
          )
        else ...[
          _sectionLabel(context, 'الأساسيون', starters.length, Colors.green),
          if (starters.isEmpty) _miniHint('لا يوجد أساسيون — حدّدهم من الاحتياط'),
          ...starters.map((p) => _playerTile(context, p)),
          const SizedBox(height: 16),
          _sectionLabel(context, 'الاحتياط', subs.length, Colors.blueGrey),
          if (subs.isEmpty) _miniHint('لا يوجد احتياط'),
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
        title: const Text('خطة الفريق الأساسية',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(hasFmt
            ? 'الحالية: $fmt  (${formationTotal(fmt)} لاعبين)'
            : 'لم تُحدَّد — اختر عدد اللاعبين والخطة'),
        trailing: OutlinedButton(
          onPressed: () => _pickFormation(context, state),
          child: Text(hasFmt ? 'تغيير' : 'تحديد'),
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
              const Center(
                child: Text('اختر خطة الفريق',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text('الصيغة: حارس-دفاع-وسط-هجوم',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              const SizedBox(height: 16),
              for (final format in kPlayerFormats) ...[
                Text('$format لاعبين',
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

  // 📝 HINT AR: عرض/مشاركة التشكيلة على الملعب (الأساسيون حسب الخطة المحفوظة).
  void _openFormationSheet(BuildContext context, TeamManageLoaded state) {
    final starters = state.players.where((p) => p.isStarter).toList();
    final use = starters.isNotEmpty ? starters : state.players;
    final lineup = use
        .map((p) => LineupPlayer(
              playerId: p.id,
              name: p.name,
              photoUrl: p.photoUrl,
              position: p.position,
              shirtNumber: p.shirtNumber,
            ))
        .toList();
    final fmt = state.team.formation;
    FormationShareSheet.show(
      context,
      title: 'تشكيلة ${state.team.name}',
      subtitle: fmt != null && fmt.isNotEmpty ? 'خطة $fmt' : 'حسب المراكز',
      players: lineup,
      formation: fmt,
    );
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
        title: Text('رقم ${p.name}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'رقم القميص', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final txt = controller.text.trim();
              final number = txt.isEmpty ? null : int.tryParse(txt);
              Navigator.pop(ctx);
              cubit.setShirtNumber(p, number);
            },
            child: const Text('حفظ'),
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
                  Text(p.shirtNumber != null ? 'رقم ${p.shirtNumber}' : 'بلا رقم',
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
                  p.isStarter ? 'أساسي' : 'احتياط',
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
        trailing: p.isClaimed
            ? const Text('مرتبط', style: TextStyle(color: Colors.blue))
            : Text('غير مرتبط', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
              child: Text('مركز ${p.name}',
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
        title: const Text('ربط لاعب بالكود'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل «كود اللاعب» الذي يظهر في ملفه الشخصي:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'مثال: A1B2C3D4',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(ToobaSnackBar.buildInfo('جارٍ الربط...'));
              try {
                await FunctionsService()
                    .linkPlayerByCode(cubit.teamId, code);
                messenger.showSnackBar(
                    ToobaSnackBar.buildSuccess('تمت إضافة اللاعب للتشكيلة'));
                await Future.delayed(const Duration(milliseconds: 800));
                await cubit.load();
              } on FirebaseFunctionsException catch (e) {
                messenger.showSnackBar(ToobaSnackBar.buildError(
                    e.message ?? 'تعذّر ربط اللاعب'));
              } catch (_) {
                messenger.showSnackBar(
                    ToobaSnackBar.buildError('تعذّر ربط اللاعب'));
              }
            },
            child: const Text('ربط'),
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
}
