import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
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
import '../referee/referee_profile_screen.dart';
import '../subscription/subscription_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.settings),
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
                title: Text(AppLocalizations.of(context)!.mySubscription),
                subtitle: Text(
                    authState.user.isSubscriptionActive
                        ? (authState.user.subscriptionStatus == 'free_trial'
                            ? AppLocalizations.of(context)!.activeFreeTrial
                            : AppLocalizations.of(context)!.activeSubscriber)
                        : AppLocalizations.of(context)!.notSubscribedActivate,
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

          // ── كارت الحكم (لمن يملك صلاحية/دور حكم) ──
          if (authState is AuthAuthenticated &&
              authState.user.isReferee) ...[
            _card(context, isDark, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.sports, color: theme.colorScheme.primary),
                title: Text(AppLocalizations.of(context)!.myRefereeMatches),
                subtitle: Text(AppLocalizations.of(context)!.assignedMatches,
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => Navigator.push(
                  context,
                  ToobaRoute.to(RefereeMatchesScreen(
                      refereeUid: authState.user.id)),
                ),
              ),
              const Divider(height: 1),
              // 📝 HINT AR: صفحة الحكم العامة (تعديل المدينة/النبذة لصاحبها).
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                title: Text(AppLocalizations.of(context)!.myRefereeProfile),
                subtitle: Text(AppLocalizations.of(context)!.publicProfileAndEdit,
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => Navigator.push(
                  context,
                  ToobaRoute.to(RefereeProfileScreen(
                      refereeUid: authState.user.id,
                      refereeName: authState.user.name)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          _section(context, AppLocalizations.of(context)!.appearance),
          _card(context, isDark, [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.darkMode),
              value: isDark,
              onChanged: (_) => context.read<ThemeCubit>().toggle(),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, AppLocalizations.of(context)!.language),
          _card(context, isDark, [
            RadioGroup<String>(
              groupValue: locale.languageCode,
              onChanged: (v) {
                if (v == null) return;
                context.read<LocaleCubit>().setLocale(Locale(v));
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.arabic),
                    value: 'ar',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.english),
                    value: 'en',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.kurdish),
                    value: 'ku',
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, AppLocalizations.of(context)!.aboutAppAndPolicies),
          _card(context, isDark, [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined,
                  color: theme.colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.privacyPolicy),
              trailing: const Icon(Icons.chevron_left, size: 20),
              onTap: () => Navigator.push(context,
                  ToobaRoute.to(const PrivacyPolicyScreen())),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.description_outlined,
                  color: theme.colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.termsConditions),
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
                  title: Text(AppLocalizations.of(context)!.appVersion),
                  trailing: Text(v, style: const TextStyle(color: Colors.grey)),
                );
              },
            ),
          ]),

          // ── منطقة الحساب (حذف + خروج) — للمستخدم المسجّل فقط ──
          if (authState is AuthAuthenticated) ...[
            const SizedBox(height: 16),
            _section(context, AppLocalizations.of(context)!.account),
            _card(context, isDark, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: Text(AppLocalizations.of(context)!.logout),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => _showLogoutDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.deleteAccount,
                    style: const TextStyle(color: Colors.red)),
                subtitle: Text(AppLocalizations.of(context)!.deleteAccountSub,
                    style: const TextStyle(fontSize: 12)),
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
          backgroundColor: isDark ? const Color(0xFF1A3050) : Colors.grey[200],
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
            snap.data ?? _roleLabel(AppLocalizations.of(context)!, user),
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
            title: Text(AppLocalizations.of(context)!.profileAndPlayerDetails),
            subtitle: Text(AppLocalizations.of(context)!.viewAndEditData,
                style: const TextStyle(fontSize: 12)),
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
        Text(AppLocalizations.of(context)!.youAreVisitor),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => context.read<AuthCubit>().logout(),
          icon: const Icon(Icons.login),
          label: Text(AppLocalizations.of(context)!.loginOrRegister),
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

  String _roleLabel(AppLocalizations loc, UserModel user) {
    switch (user.role) {
      case 'captain':
        return loc.teamCaptain;
      case 'admin':
        return loc.platformAdmin;
      default:
        return loc.player;
    }
  }

  Future<String> _resolveTeamLabel(BuildContext context, UserModel user) async {
    final loc = AppLocalizations.of(context)!;
    if (user.role == 'admin') return loc.platformAdmin;
    final teamRepo = context.read<TeamRepository>();
    try {
      if (user.role == 'captain') {
        final team = await teamRepo.getTeamByCaptain(user.id);
        if (!context.mounted) return _roleLabel(loc, user);
        return team != null ? '${loc.captainOfTeam}${team.name}' : loc.captainNoTeam;
      }
      // لاعب
      if (user.linkedPlayerId != null && user.linkedPlayerId!.isNotEmpty) {
        final player = await context
            .read<PlayerRepository>()
            .getPlayerById(user.linkedPlayerId!);
        if (!context.mounted) return _roleLabel(loc, user);
        if (player.currentTeamId.isNotEmpty) {
          final team = await teamRepo.getTeamById(player.currentTeamId);
          return '${loc.playerWithTeam}${team.name}';
        }
      }
      return loc.playerNoTeam;
    } catch (_) {
      return _roleLabel(loc, user);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.confirmLogoutMsg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.logout),
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
        title: Text(AppLocalizations.of(context)!.deleteAccountPermanently),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(AppLocalizations.of(context)!.deleteAccountPermanentlyMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                messenger
                  .showSnackBar(ToobaSnackBar.buildInfo(AppLocalizations.of(context)!.deletingAccount));
                await FunctionsService().deleteMyAccount();
                await authCubit.logout();
                if (!context.mounted) return;
                messenger
                    .showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.accountDeleted));
              } catch (e) {
                messenger.showSnackBar(
                    ToobaSnackBar.buildError(_deleteErrorMessage(context, e)));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.permanentDelete),
          ),
        ],
      ),
    );
  }

  String _deleteErrorMessage(BuildContext context, Object e) {
    final loc = AppLocalizations.of(context)!;
    final msg = e.toString();
    if (msg.contains('كابتن')) {
      return loc.captainDeleteError;
    }
    return loc.generalError;
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
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: children),
        ),
      );
}
