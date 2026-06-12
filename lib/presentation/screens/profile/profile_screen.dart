import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/core/tooba_card.dart';
import '../admin/admin_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1877F2), Color(0xFF0C5EBF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(LucideIcons.user, size: 40, color: Colors.grey)),
                    SizedBox(height: 12),
                    Text('أحمد العراقي', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('@ahmed_iq', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('مباريات', '24')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('أهداف', '12')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('أسيست', '5')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ToobaCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildListTile(context, LucideIcons.settings, 'الإعدادات'),
                        const Divider(height: 1),
                        _buildListTile(context, LucideIcons.moon, 'الوضع الليلي'),
                        const Divider(height: 1),
                        _buildListTile(context, LucideIcons.bell, 'الإشعارات'),
                        const Divider(height: 1),
                        _buildListTile(context, LucideIcons.shieldAlert, 'لوحة الإدارة', color: Colors.teal, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                        }),
                        const Divider(height: 1),
                        _buildListTile(context, LucideIcons.logOut, 'تسجيل الخروج', color: Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return ToobaCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1877F2))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronLeft, size: 20),
      onTap: onTap ?? () {},
    );
  }
}
