import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/report_model.dart';
import '../reports/submit_report_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: بطاقة/صفحة اللاعب — تعرض إحصائياته (مباريات/أهداف/صناعة/بطاقات).
/// الإحصائيات تأتي من careerStats التي يحدّثها النظام (CF) من أحداث المباريات.
/// (هذه أساس «بطاقة اللاعب القابلة للمشاركة» في المرحلة 2 — التصميم لاحقاً.)
class PlayerDetailScreen extends StatelessWidget {
  final PlayerModel player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = player.careerStats;

    ImageProvider? img;
    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      img = player.photoUrl!.startsWith('assets/')
          ? AssetImage(player.photoUrl!)
          : CachedNetworkImageProvider(player.photoUrl!) as ImageProvider;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('بطاقة اللاعب'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val != 'report') return;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                ToobaSnackBar.info(context, 'يجب تسجيل الدخول أولاً');
                return;
              }
              Navigator.push(
                context,
                ToobaRoute.to(SubmitReportScreen(
                  targetType: ReportTargetType.player,
                  targetId: player.id,
                  targetName: player.name,
                )),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('بلّغ عن هذا اللاعب',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // رأس البطاقة (تدرّج)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1877F2), Color(0xFF0C5EBF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    backgroundImage: img,
                    child: img == null
                        ? const Icon(Icons.person, size: 52, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(player.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${player.position}${player.shirtNumber != null ? ' • #${player.shirtNumber}' : ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (player.isClaimed)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('حساب موثّق',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // الإحصائيات الأساسية
            Row(
              children: [
                _statBox(context, 'مباريات', cs.matches.toString(),
                    Icons.sports_soccer),
                _statBox(context, 'أهداف', cs.goals.toString(),
                    Icons.sports_score),
                _statBox(context, 'صناعة', cs.assists.toString(),
                    Icons.handshake),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statBox(context, 'تقييم', cs.rating.toStringAsFixed(1),
                    Icons.star, color: Colors.amber),
                _statBox(context, 'بطاقات صفراء', cs.yellowCards.toString(),
                    Icons.square, color: Colors.amber),
                _statBox(context, 'بطاقات حمراء', cs.redCards.toString(),
                    Icons.square, color: Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // تفاصيل فنية
            _detailsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _statBox(BuildContext context, String label, String value, IconData icon,
      {Color? color}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? theme.colorScheme.primary, size: 26),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String foot;
    switch (player.preferredFoot) {
      case 'left':
        foot = 'يسرى';
        break;
      case 'both':
        foot = 'كلتاهما';
        break;
      case 'right':
        foot = 'يمنى';
        break;
      default:
        foot = 'غير محدد';
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التفاصيل الفنية',
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          _row('القدم المفضّلة', foot),
          _row('الطول', player.height != null ? '${player.height} سم' : 'غير محدد'),
          _row('الوزن', player.weight != null ? '${player.weight} كجم' : 'غير محدد'),
          _row('الحالة', _statusLabel(player.status)),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'injured':
        return 'مصاب';
      case 'suspended':
        return 'موقوف';
      default:
        return 'نشط';
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
