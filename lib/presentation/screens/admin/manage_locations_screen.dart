import 'package:flutter/material.dart';

class ManageLocationsScreen extends StatelessWidget {
  const ManageLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحافظات والمناطق', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLocationItem('بغداد', 'Baghdad', true),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: _buildLocationItem('الكرادة', 'Karrada', true),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: _buildLocationItem('المنصور', 'Al Mansour', false), // false = in-active
          ),
          const Divider(),
          _buildLocationItem('البصرة', 'Basra', true),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String nameAr, String nameEn, bool isActive) {
    return ListTile(
      title: Text(nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(nameEn, style: const TextStyle(color: Colors.grey)),
      trailing: Switch(
        value: isActive,
        activeTrackColor: Colors.blue,
        onChanged: (val) {},
      ),
      onTap: () {},
    );
  }
}
