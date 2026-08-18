import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';


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
    final isDark = theme.brightness == Brightness.dark;
    final hasResult = homeScore != null && awayScore != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(homeTeamName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.right),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (hasResult || isLive)
                    Text('${homeScore ?? 0} - ${awayScore ?? 0}',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: isDark ? Colors.white : Colors.black87))
                  else
                    Text('vs',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? const Color(0xFF6A8898) : Colors.grey)),
                  const SizedBox(height: 4),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF4B4B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              color: Color(0xFFFF4B4B), size: 6),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context)!.live,
                              style: const TextStyle(
                                  color: Color(0xFFFF4B4B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (dateTime != null)
                    Text(DateFormat('MMM d, h:mm a').format(dateTime!),
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF6A8898) : Colors.grey)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(awayTeamName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.left),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
