import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tooba_card.dart';
import 'tooba_team_avatar.dart';

/// 📝 HINT AR: بطاقة مباراة. تُعرض في قائمة المباريات وتفاصيل البطولة.
/// • إذا أُعطي dateTime تُعرض في سطر تحت اسمَي الفريقَين.
/// • إذا لم تُعطَ نتيجة (homeScore/awayScore == null) تُعرض «VS».
class ToobaMatchCard extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final String timeText;
  final bool isLive;
  final DateTime? dateTime; // 📝 HINT AR: يُعرض إن أُعطي

  const ToobaMatchCard({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
    required this.timeText,
    this.isLive = false,
    this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult = homeScore != null && awayScore != null;

    return ToobaCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── شريط الحالة / الموعد ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive)
                _liveBadge()
              else ...[
                Icon(
                  dateTime != null
                      ? Icons.calendar_month
                      : Icons.sports_soccer_outlined,
                  size: 13,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    color: dateTime != null && !hasResult
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    fontSize: 13,
                    fontWeight: dateTime != null && !hasResult
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── الفريقان والنتيجة ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الفريق المضيف
              Expanded(
                child: Column(
                  children: [
                    ToobaTeamAvatar(logoUrl: homeTeamLogo ?? '', radius: 28),
                    const SizedBox(height: 8),
                    Text(
                      homeTeamName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // النتيجة أو VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: hasResult
                    ? Text(
                        '$homeScore - $awayScore',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      )
                    : const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
              ),

              // الفريق الضيف
              Expanded(
                child: Column(
                  children: [
                    ToobaTeamAvatar(logoUrl: awayTeamLogo ?? '', radius: 28),
                    const SizedBox(height: 8),
                    Text(
                      awayTeamName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── التاريخ والوقت الكامل (إن توفّر وليست المباراة منتهية) ──
          if (dateTime != null && !hasResult) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time,
                    size: 13, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE، d MMMM yyyy • HH:mm', 'ar')
                      .format(dateTime!),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'مباشر',
            style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
