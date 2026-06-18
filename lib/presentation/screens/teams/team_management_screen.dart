import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_manage_cubit.dart';
import '../../cubits/team/team_manage_state.dart';
import '../../../data/models/player_model.dart';
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
          } else if (state is TeamManageInviteReady) {
            _showInviteDialog(context, state.code, state.playerName);
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
        Builder(builder: (_) {
          final starters = state.players.where((p) => p.isStarter).length;
          return Row(
            children: [
              Text('التشكيلة (${state.players.length})',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('أساسيون: $starters',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ),
            ],
          );
        }),
        const SizedBox(height: 4),
        Text('اضغط شارة «أساسي/احتياط» لتغيير دور اللاعب في التشكيلة',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 8),
        if (state.players.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('لا يوجد لاعبون بعد — أضِف لاعبيك بزر «إضافة لاعب»',
                style: TextStyle(color: Colors.grey[600])),
          )
        else
          ...state.players.map((p) => _playerTile(context, p)),
        const SizedBox(height: 80),
      ],
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
        subtitle: Row(
          children: [
            Text(p.position),
            const SizedBox(width: 8),
            // 📝 HINT AR: شارة قابلة للضغط لتبديل أساسي/احتياط.
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
        trailing: p.isClaimed
            ? const Text('مرتبط', style: TextStyle(color: Colors.blue))
            : OutlinedButton.icon(
                icon: const Icon(Icons.link, size: 16),
                label: const Text('دعوة'),
                onPressed: () =>
                    context.read<TeamManageCubit>().generateInvite(p),
              ),
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

  void _showInviteDialog(BuildContext context, String code, String playerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز دعوة اللاعب'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أعطِ هذا الرمز لـ «$playerName» ليربط حسابه بسجله من شاشة حسابه:',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SelectableText(
              code,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            const Text('صالح لمدة 7 أيام',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ الرمز'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              ToobaSnackBar.info(context, 'تم نسخ الرمز');
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
