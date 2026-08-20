import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../widgets/core/decorated_background.dart';
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
import '../../../l10n/app_localizations.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminDashboardTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAdminCard(
              context,
              icon: Icons.location_on,
              title: AppLocalizations.of(context)!.manageLocationsTitle,
              subtitle: AppLocalizations.of(context)!.manageLocationsSubtitle,
              color: Colors.teal,
              onTap: () {
                Navigator.push(context, ToobaRoute.to(const ManageLocationsScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.verified_user,
              title: AppLocalizations.of(context)!.manageRolesTitle,
              subtitle: AppLocalizations.of(context)!.manageRolesSubtitle,
              color: Colors.blue,
              onTap: () {
                Navigator.push(context, ToobaRoute.to(const ManageRolesScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.flag,
              title: AppLocalizations.of(context)!.adminReportsTitle,
              subtitle: AppLocalizations.of(context)!.adminReportsSubtitle,
              color: Colors.red,
              onTap: () => Navigator.push(context,
                  ToobaRoute.to(const AdminReportsScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.emoji_events,
              title: AppLocalizations.of(context)!.adminTournamentsTitle,
              subtitle: AppLocalizations.of(context)!.adminTournamentsSubtitle,
              color: Colors.amber.shade800,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminTournamentsScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.image,
              title: AppLocalizations.of(context)!.adminBannersTitle,
              subtitle: AppLocalizations.of(context)!.adminBannersSubtitle,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminBannersScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.article,
              title: AppLocalizations.of(context)!.adminNewsTitle,
              subtitle: AppLocalizations.of(context)!.adminNewsSubtitle,
              color: Colors.green.shade700,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminNewsScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.how_to_reg,
              title: AppLocalizations.of(context)!.adminRefereeApplicationsTitle,
              subtitle: AppLocalizations.of(context)!.adminRefereeApplicationsSubtitle,
              color: Colors.teal.shade700,
              onTap: () => Navigator.push(context,
                  ToobaRoute.to(const AdminRefereeApplicationsScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.balance,
              title: AppLocalizations.of(context)!.adminDisputesTitle,
              subtitle: AppLocalizations.of(context)!.adminDisputesSubtitle,
              color: Colors.purple,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminDisputesScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.sports_mma,
              title: AppLocalizations.of(context)!.adminChallengesTitle,
              subtitle: AppLocalizations.of(context)!.adminChallengesSubtitle,
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminChallengesScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.grid_view,
              title: AppLocalizations.of(context)!.adminSectionsTitle,
              subtitle: AppLocalizations.of(context)!.adminSectionsSubtitle,
              color: Colors.blueGrey,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminSectionsScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.confirmation_number,
              title: AppLocalizations.of(context)!.adminSubscriptionsTitle,
              subtitle: AppLocalizations.of(context)!.adminSubscriptionsSubtitle,
              color: Colors.teal,
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const AdminSubscriptionsScreen())),
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              context,
              icon: Icons.check_circle,
              title: AppLocalizations.of(context)!.adminVerifyTeamsTitle,
              subtitle: AppLocalizations.of(context)!.comingSoon,
              color: Colors.amber.shade700,
              onTap: () {},
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
        ),
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
          child: Text(subtitle, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)),
        ),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
