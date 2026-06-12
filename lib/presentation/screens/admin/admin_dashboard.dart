import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'manage_locations_screen.dart';

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
            title: 'إدارة المحافظات والمناطق',
            subtitle: 'تفعيل وتعديل أسماء المناطق الجغرافية',
            color: Colors.teal,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageLocationsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.sliders,
            title: 'إعدادات المنصة المركزية',
            subtitle: 'إيقاف وتشغيل الأقسام (البطولات، إلخ)',
            color: Colors.blue,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            context,
            icon: LucideIcons.shieldCheck,
            title: 'إدارة توثيق الفرق',
            subtitle: 'منح وسام التوثيق (العلامة الزرقاء)',
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
            color: color.withOpacity(0.1),
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
