import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/locale_cubit.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/services/functions_service.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_conditions_screen.dart';
import '../profile/profile_screen.dart';
import '../matches/referee_matches_screen.dart';
import '../subscription/subscription_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: شاشة الإعدادات (تبويب) — في الأعلى صورة المستخدم واسمه وكارت
/// تفاصيله (ينقل للملف الشخصي)، يليها المظهر واللغة والسياسات وحذف الحساب.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = context.watch<LocaleCubit>().state;
    final authState = context.watch<AuthCubit>().state;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── ترويسة المستخدم + كارت الملف الشخصي ──
          if (authState is AuthAuthenticated)
            _profileHeader(context, isDark, authState),
          if (authState is AuthVisitor) _visitorHeader(context, theme),
          const SizedBox(height: 20),

          // ── كارت الاشتراك (للكابتن — المرحلة 8) ──
          if (authState is AuthAuthenticated &&
              authState.user.isCaptain) ...[
            _card(context, isDark, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.workspace_premium,
                    color: authState.user.isSubscriptionActive
                        ? Colors.green
                        : theme.colorScheme.primary),
                title: const Text('اشتراكي'),
                subtitle: Text(
                    authState.user.isSubscriptionActive
                        ? (authState.user.subscriptionStatus == 'free_trial'
                            ? 'تجربة مجانية فعّالة'
                            : 'مشترك فعّال')
                        : 'غير مشترك — فعّل للتحدّيات',
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => Navigator.push(
                  context,
                  ToobaRoute.to(const SubscriptionScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // ── كارت الحكم (لمن يملك صلاحية حكم فقط) ──
          if (authState is AuthAuthenticated &&
              authState.user.adminPermissions.contains('referee')) ...[
            _card(context, isDark, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.sports, color: theme.colorScheme.primary),
                title: const Text('مبارياتي كحكم'),
                subtitle: const Text('المباريات المعيّن لها',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => Navigator.push(
                  context,
                  ToobaRoute.to(RefereeMatchesScreen(
                      refereeUid: authState.user.id)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          _section(context, 'المظهر'),
          _card(context, isDark, [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary),
              title: const Text('الوضع الداكن'),
              value: isDark,
              onChanged: (_) => context.read<ThemeCubit>().toggle(),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'اللغة'),
          _card(context, isDark, [
            RadioGroup<String>(
              groupValue: locale.languageCode,
              onChanged: (v) {
                if (v == null) return;
                context.read<LocaleCubit>().setLocale(Locale(v));
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('العربية'),
                    value: 'ar',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('English'),
                    value: 'en',
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'عن التطبيق والسياسات'),
          _card(context, isDark, [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('سياسة الخصوصية'),
              trailing: const Icon(Icons.chevron_left, size: 20),
              onTap: () => Navigator.push(context,
                  ToobaRoute.to(const PrivacyPolicyScreen())),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.description_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('الشروط والأحكام'),
              trailing: const Icon(Icons.chevron_left, size: 20),
              onTap: () => Navigator.push(context,
                  ToobaRoute.to(const TermsConditionsScreen())),
            ),
            const Divider(height: 1),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                final v = snap.hasData
                    ? '${snap.data!.version} (${snap.data!.buildNumber})'
                    : '...';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline,
                      color: theme.colorScheme.primary),
                  title: const Text('إصدار التطبيق'),
                  trailing: Text(v, style: const TextStyle(color: Colors.grey)),
                );
              },
            ),
          ]),

          // ── منطقة الحساب (حذف + خروج) — للمستخدم المسجّل فقط ──
          if (authState is AuthAuthenticated) ...[
            const SizedBox(height: 16),
            _section(context, 'الحساب'),
            _card(context, isDark, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('تسجيل الخروج'),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => _showLogoutDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('حذف الحساب',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text('حذف نهائي لحسابك وبياناتك الشخصية',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ]),
          ],

          const SizedBox(height: 24),
          Center(
            child: Text('منصة طوبة ⚽',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: ترويسة المستخدم — صورة + اسم + دور، يليها كارت ينقل للملف الشخصي.
  Widget _profileHeader(
      BuildContext context, bool isDark, AuthAuthenticated state) {
    final theme = Theme.of(context);
    final user = state.user;
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          backgroundImage: _imageProvider(user.profileImage),
          child: _imageProvider(user.profileImage) == null
              ? Icon(Icons.person,
                  size: 44,
                  color: isDark ? Colors.grey[600] : Colors.grey[400])
              : null,
        ),
        const SizedBox(height: 12),
        Text(user.name,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        // 📝 HINT AR: الصفة + الفريق (لاعب مع فريق X / كابتن فريق X).
        FutureBuilder<String>(
          future: _resolveTeamLabel(context, user),
          builder: (context, snap) => Text(
            snap.data ?? _roleLabel(user.role),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        _card(context, isDark, [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_circle_outlined,
                color: theme.colorScheme.primary),
            title: const Text('الملف الشخصي وتفاصيل اللاعب'),
            subtitle: const Text('عرض وتعديل بياناتك',
                style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_left, size: 20),
            onTap: () =>
                Navigator.push(context, ToobaRoute.to(const ProfileScreen())),
          ),
        ]),
      ],
    );
  }

  Widget _visitorHeader(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 12),
        const Text('أنت مسجّل كزائر'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => context.read<AuthCubit>().logout(),
          icon: const Icon(Icons.login),
          label: const Text('تسجيل الدخول / إنشاء حساب'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  ImageProvider? _imageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    return NetworkImage(path);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'captain':
        return 'كابتن فريق';
      case 'admin':
        return 'مدير المنصة';
      default:
        return 'لاعب';
    }
  }

  // 📝 HINT AR: «كابتن فريق X» / «لاعب مع فريق X» — يحلّ فريق المستخدم.
  Future<String> _resolveTeamLabel(BuildContext context, UserModel user) async {
    if (user.role == 'admin') return 'مدير المنصة';
    final teamRepo = context.read<TeamRepository>();
    try {
      if (user.role == 'captain') {
        final team = await teamRepo.getTeamByCaptain(user.id);
        return team != null ? 'كابتن فريق ${team.name}' : 'كابتن (بلا فريق)';
      }
      // لاعب
      if (user.linkedPlayerId != null && user.linkedPlayerId!.isNotEmpty) {
        final player = await context
            .read<PlayerRepository>()
            .getPlayerById(user.linkedPlayerId!);
        if (player.currentTeamId.isNotEmpty) {
          final team = await teamRepo.getTeamById(player.currentTeamId);
          return 'لاعب مع فريق ${team.name}';
        }
      }
      return 'لاعب (بلا فريق)';
    } catch (_) {
      return _roleLabel(user.role);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: حذف الحساب نهائياً — تأكيد ثم استدعاء Cloud Function ثم خروج.
  void _showDeleteAccountDialog(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب نهائياً'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
          'سيتم حذف حسابك وبياناتك الشخصية نهائياً ولا يمكن التراجع.\n\n'
          'ملاحظة: إن كنت كابتن فريق، احذف فريقك أو انقل الكابتنية أولاً.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              messenger
                  .showSnackBar(ToobaSnackBar.buildInfo('جارٍ حذف الحساب...'));
              try {
                await FunctionsService().deleteMyAccount();
                await authCubit.logout();
                messenger
                    .showSnackBar(ToobaSnackBar.buildSuccess('تم حذف حسابك'));
              } catch (e) {
                messenger.showSnackBar(
                    ToobaSnackBar.buildError(_deleteErrorMessage(e)));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  String _deleteErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('كابتن')) {
      return 'أنت كابتن فريق — احذف فريقك أو انقل الكابتنية أولاً.';
    }
    return 'تعذّر حذف الحساب — حاول مرة أخرى لاحقاً.';
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _card(BuildContext context, bool isDark, List<Widget> children) =>
      Material(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: Column(children: children),
      );
}
