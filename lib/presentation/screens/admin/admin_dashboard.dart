import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'manage_locations_screen.dart';
import 'manage_roles_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_news_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_challenges_screen.dart';
import 'admin_subscriptions_screen.dart';
import 'admin_tournaments_screen.dart';
import 'admin_referee_applications_screen.dart';
import 'admin_sections_screen.dart';
import '../../../app/router/tooba_route.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(
            context,
            icon: LucideIcons.mapPin,
            title: 'إدارة المواقع',
            subtitle: 'المحافظات والمناطق المسموح باللعب فيها',
            color: Colors.teal,
            onTap: () {
              Navigator.push(context, ToobaRoute.to(const ManageLocationsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.shieldCheck,
            title: 'إدارة الصلاحيات',
            subtitle: 'منح ألقاب المنظمين والحكام',
            color: Colors.blue,
            onTap: () {
              Navigator.push(context, ToobaRoute.to(const ManageRolesScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.flag,
            title: 'البلاغات',
            subtitle: 'مراجعة البلاغات الواردة عن لاعبين وفرق',
            color: Colors.red,
            onTap: () => Navigator.push(context,
                ToobaRoute.to(const AdminReportsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.trophy,
            title: 'إدارة البطولات',
            subtitle: 'تعديل الأسماء والصور والكؤوس والجوائز',
            color: Colors.amber.shade800,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminTournamentsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.image,
            title: 'إدارة الإعلانات',
            subtitle: 'بانرات سلايدر الصفحة الرئيسية',
            color: Colors.indigo,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminBannersScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.newspaper,
            title: 'إدارة الأخبار',
            subtitle: 'نشر وتعديل أخبار الصفحة الرئيسية',
            color: Colors.green.shade700,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminNewsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.userCheck,
            title: 'طلبات التحكيم',
            subtitle: 'موافقة/رفض طلبات الراغبين بالتحكيم',
            color: Colors.teal.shade700,
            onTap: () => Navigator.push(context,
                ToobaRoute.to(const AdminRefereeApplicationsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.scale,
            title: 'نزاعات فكّ الارتباط',
            subtitle: 'طلبات خروج رفضها الكباتن وصعّدها اللاعبون',
            color: Colors.purple,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminDisputesScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.swords,
            title: 'إدارة التحديات',
            subtitle: 'إلغاء طلبات التحدّي المتروكة (بلا متقدّمين منذ أيام)',
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminChallengesScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.layoutGrid,
            title: 'إعدادات الأقسام',
            subtitle: 'إظهار/إخفاء أقسام التطبيق (مثل البطولات)',
            color: Colors.blueGrey,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminSectionsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.ticket,
            title: 'أكواد التفعيل',
            subtitle: 'توليد أكواد الاشتراك + مدة التجربة + واتساب التفعيل',
            color: Colors.teal,
            onTap: () => Navigator.push(
                context, ToobaRoute.to(const AdminSubscriptionsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.checkCircle,
            title: 'توثيق الفرق',
            subtitle: 'قريباً...',
            color: Colors.amber.shade700,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: const Icon(LucideIcons.chevronLeft, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
