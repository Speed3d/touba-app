import '../../../core/utils/image_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/report_model.dart';
import '../reports/submit_report_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

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
          : ImageHelper.getProvider(player.photoUrl!);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.playerCard),
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
                ToobaSnackBar.info(context, AppLocalizations.of(context)!.loginFirst);
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
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.reportThisPlayer,
                        style: const TextStyle(color: Colors.red)),
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
                  if (player.claimedByUid != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.verifiedPlayer,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
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
                _statBox(context, AppLocalizations.of(context)!.matchesPlayed, cs.matches.toString(),
                    Icons.sports_soccer),
                _statBox(context, AppLocalizations.of(context)!.goals, cs.goals.toString(),
                    Icons.sports_score),
                _statBox(context, AppLocalizations.of(context)!.assists, cs.assists.toString(),
                    Icons.handshake),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statBox(context, AppLocalizations.of(context)!.rating, cs.rating.toStringAsFixed(1),
                    Icons.star, color: Colors.amber),
                _statBox(context, AppLocalizations.of(context)!.yellowCards, cs.yellowCards.toString(),
                    Icons.square, color: Colors.amber),
                _statBox(context, AppLocalizations.of(context)!.redCards, cs.redCards.toString(),
                    Icons.square, color: Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // تفاصيل فنية
            _detailsCard(context),
            // نبذة عن اللاعب
            if (player.bio != null && player.bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _bioCard(context),
            ],
            // معرض صور اللاعب
            if (player.gallery.isNotEmpty) ...[
              const SizedBox(height: 16),
              _galleryCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bioCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          Text(AppLocalizations.of(context)!.bioLabel,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          Text(player.bio!,
              style: TextStyle(
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _galleryCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          Text(AppLocalizations.of(context)!.gallery,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: player.gallery.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: player.gallery[i],
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  placeholder: (c, u) =>
                      Container(width: 110, color: Colors.grey.shade200),
                  errorWidget: (c, u, e) => Container(
                      width: 110,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey)),
                ),
              ),
            ),
          ),
        ],
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
        foot = AppLocalizations.of(context)!.footLeft;
        break;
      case 'both':
        foot = AppLocalizations.of(context)!.footBoth;
        break;
      case 'right':
        foot = AppLocalizations.of(context)!.footRight;
        break;
      default:
        foot = AppLocalizations.of(context)!.notSpecified;
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
          Text(AppLocalizations.of(context)!.technicalDetails,
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(),
          _row(AppLocalizations.of(context)!.preferredFoot, foot),
          _row(AppLocalizations.of(context)!.age, player.age != null ? AppLocalizations.of(context)!.yearsOldX(player.age.toString()) : AppLocalizations.of(context)!.notSpecified),
          _row(AppLocalizations.of(context)!.height, player.height != null ? AppLocalizations.of(context)!.cmX(player.height.toString()) : AppLocalizations.of(context)!.notSpecified),
          _row(AppLocalizations.of(context)!.weight, player.weight != null ? AppLocalizations.of(context)!.kgX(player.weight.toString()) : AppLocalizations.of(context)!.notSpecified),
          _row(AppLocalizations.of(context)!.status, _statusLabel(context, player.status)),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, String s) {
    switch (s) {
      case 'injured':
        return AppLocalizations.of(context)!.statusInjured;
      case 'suspended':
        return AppLocalizations.of(context)!.statusSuspended;
      default:
        return AppLocalizations.of(context)!.statusActive;
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
