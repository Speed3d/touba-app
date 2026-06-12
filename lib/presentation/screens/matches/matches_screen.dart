import 'package:flutter/material.dart';
import '../../widgets/core/tooba_match_card.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المباريات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildDateTab('أمس', false),
                _buildDateTab('اليوم', true),
                _buildDateTab('غداً', false),
                _buildDateTab('الخميس', false),
                _buildDateTab('الجمعة', false),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('بطولة بغداد الكبرى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          ),
          ToobaMatchCard(
            homeTeamName: 'نجوم المنصور',
            awayTeamName: 'شباب الكرادة',
            homeScore: 2,
            awayScore: 1,
            timeText: '70\'',
            isLive: true,
          ),
          SizedBox(height: 16),
          ToobaMatchCard(
            homeTeamName: 'أبطال الدورة',
            awayTeamName: 'صقور الشعب',
            timeText: '20:00',
            isLive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1877F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
