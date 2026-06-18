import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/services/functions_service.dart';
import '../../../data/services/notification_service.dart';
import 'edit_profile_screen.dart';
import '../admin/admin_dashboard.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_conditions_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: يعرض الحساب الشخصي فقط (الاسم/الدور/التواصل). الإحصائيات الكروية
/// أصبحت في سجل اللاعب (PlayerModel) وتُعرض في «بطاقة اللاعب» عند ربط الحساب.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthVisitor) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'أنت مسجل كزائر',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
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
            ),
          );
        }

        if (state is AuthAuthenticated) {
          final user = state.user;
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('الملف الشخصي'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                // جرس الإشعارات مع badge العدد غير المقروء
                StreamBuilder<int>(
                  stream: NotificationService.instance.unreadCountStream,
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          tooltip: 'الإشعارات',
                          onPressed: () => Navigator.push(
                            context,
                            ToobaRoute.to(const NotificationsScreen()),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 1.5),
                              ),
                              constraints:
                                  const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      ToobaRoute.to(const EditProfileScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: _imageProvider(user.profileImage),
                          child: _imageProvider(user.profileImage) == null
                              ? Icon(Icons.person,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400])
                              : null,
                        ),
                        if (user.isCaptain)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star,
                                  size: 20, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(user.role),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // بطاقة معلومات التواصل
                  _infoCard(context, isDark, [
                    _row('رقم الهاتف', user.phone, Icons.phone),
                    if (user.email.isNotEmpty)
                      _row('البريد الإلكتروني', user.email, Icons.email),
                  ]),
                  // 📝 HINT AR: قسم ربط اللاعب للاعبين فقط (role == user) — لا
                  // يُعرض للكابتن ولا للأدمن (لا يحتاجان بطاقة لاعب).
                  if (user.role == 'user') ...[
                    const SizedBox(height: 16),
                    _infoCard(context, isDark, [
                      Row(
                        children: [
                          Icon(
                            user.linkedPlayerId != null
                                ? Icons.verified
                                : Icons.sports_soccer,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.linkedPlayerId != null
                                  ? 'حسابك مرتبط ببطاقة لاعب'
                                  : 'لم تربط حسابك بسجل لاعب بعد — يرسل لك الكابتن رمز دعوة للربط',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (user.linkedPlayerId == null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _showClaimDialog(context),
                            icon: const Icon(Icons.link),
                            label: const Text('ربط حسابي بكود'),
                          ),
                        ),
                      ],
                    ]),
                  ],

                  if (user.isAdmin) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(context, ToobaRoute.to(const AdminDashboard()));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'لوحة تحكم الإدارة',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 📝 HINT AR: روابط السياسات (مطلوبة للمتجر) — متاحة للجميع.
                  const SizedBox(height: 16),
                  _infoCard(context, isDark, [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.privacy_tip_outlined,
                          color: theme.colorScheme.primary),
                      title: const Text('سياسة الخصوصية'),
                      trailing: const Icon(Icons.chevron_left, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        ToobaRoute.to(const PrivacyPolicyScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.description_outlined,
                          color: theme.colorScheme.primary),
                      title: const Text('الشروط والأحكام'),
                      trailing: const Icon(Icons.chevron_left, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        ToobaRoute.to(const TermsConditionsScreen()),
                      ),
                    ),
                  ]),

                  // 📝 HINT AR: منطقة الخطر — حذف الحساب نهائياً (مطلوب للمتجر).
                  const SizedBox(height: 16),
                  _infoCard(context, isDark, [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_forever,
                          color: Colors.red),
                      title: const Text('حذف الحساب',
                          style: TextStyle(color: Colors.red)),
                      subtitle: const Text(
                        'حذف نهائي لحسابك وبياناتك الشخصية',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_left, size: 20),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ]),

                  const SizedBox(height: 32),
                ],
              ),

            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // 📝 HINT AR: يدعم الأصول المحلية (assets/) أو روابط الشبكة (cache-first عبر صفحات أخرى).
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

  Widget _infoCard(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 📝 HINT AR: ربط الحساب بسجل لاعب عبر رمز الدعوة (يستدعي Cloud Function).
  void _showClaimDialog(BuildContext context) {
    final controller = TextEditingController();
    final authCubit = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ربط حسابك بسجل لاعب'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل رمز الدعوة الذي أعطاك إياه الكابتن:'),
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              messenger.showSnackBar(ToobaSnackBar.buildInfo('جارٍ الربط...'));
              try {
                await FunctionsService().claimPlayerViaInvite(code);
                await authCubit.refreshUser();
                messenger.showSnackBar(ToobaSnackBar.buildSuccess('تم ربط حسابك بنجاح!'));
              } on FirebaseFunctionsException catch (e) {
                // 📝 HINT AR: نُظهر رسالة الخادم الفعلية (رمز غير صالح/مستخدم/منتهٍ)
                // بدل رسالة عامة، فيعرف اللاعب سبب الفشل بدقّة.
                messenger.showSnackBar(ToobaSnackBar.buildError(
                    e.message ?? 'تعذّر الربط — تحقّق من صحة الرمز أو صلاحيته'));
              } catch (_) {
                messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر الربط — تحقّق من صحة الرمز أو صلاحيته'));
              }
            },
            child: const Text('ربط'),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: حذف الحساب نهائياً — تأكيد قوي ثم استدعاء Cloud Function.
  // عند النجاح نسجّل الخروج محلياً (حساب المصادقة حُذف من الخادم).
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              messenger.showSnackBar(ToobaSnackBar.buildInfo('جارٍ حذف الحساب...'));
              try {
                await FunctionsService().deleteMyAccount();
                await authCubit.logout();
                messenger.showSnackBar(ToobaSnackBar.buildSuccess('تم حذف حسابك'));
              } catch (e) {
                messenger.showSnackBar(ToobaSnackBar.buildError(_deleteErrorMessage(e)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  // 📝 HINT AR: استخراج رسالة عربية واضحة من خطأ الدالة السحابية.
  String _deleteErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('كابتن')) {
      return 'أنت كابتن فريق — احذف فريقك أو انقل الكابتنية أولاً.';
    }
    return 'تعذّر حذف الحساب — حاول مرة أخرى لاحقاً.';
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
