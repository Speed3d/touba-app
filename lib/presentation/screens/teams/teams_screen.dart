import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/core/tooba_card.dart';
import '../../widgets/core/tooba_team_avatar.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفرق', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(LucideIcons.filter), onPressed: () {}),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isElite = index % 3 == 0;
          return ToobaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToobaTeamAvatar(logoUrl: '', radius: 36, isElite: isElite),
                const SizedBox(height: 12),
                const Text(
                  'نجوم المنصور',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text('1450', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
