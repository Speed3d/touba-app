import 'package:flutter/material.dart';
import 'tooba_card.dart';
import 'tooba_team_avatar.dart';

class ToobaMatchCard extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final String timeText;
  final bool isLive;

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
  });

  @override
  Widget build(BuildContext context) {
    return ToobaCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'مباشر',
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  timeText,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home Team
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
              
              // Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: homeScore != null && awayScore != null
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

              // Away Team
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
        ],
      ),
    );
  }
}
