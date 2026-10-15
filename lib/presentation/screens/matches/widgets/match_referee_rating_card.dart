import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router/tooba_route.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../referee/referee_profile_screen.dart';

/// 📝 HINT AR: بطاقة تقييم الحكم — متوسطه الحالي + زر لفتح منتقي النجوم للمؤهَّلين.
class MatchRefereeRatingCard extends StatelessWidget {
  final MatchModel match;
  final bool canRate;
  final bool alreadyRated;
  final VoidCallback onRate;

  const MatchRefereeRatingCard({
    super.key,
    required this.match,
    required this.canRate,
    required this.alreadyRated,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (match.refereeId == null || match.refereeId!.isEmpty) {
      return const SizedBox.shrink();
    }
    final repo = context.read<MatchRepository>();
    return FutureBuilder<({double rating, int count})>(
      future: repo.getRefereeProfile(match.refereeId!),
      builder: (context, snap) {
        final avg = snap.data?.rating ?? 0;
        final count = snap.data?.count ?? 0;
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    ToobaRoute.to(RefereeProfileScreen(
                        refereeUid: match.refereeId!,
                        refereeName: match.refereeName)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(AppLocalizations.of(context)!.refereeNameX(match.refereeName ?? "—"),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline)),
                      ),
                      if (count > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text('${avg.toStringAsFixed(1)} ($count)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_left,
                          size: 18, color: Colors.grey[400]),
                    ],
                  ),
                ),
                if (canRate) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: alreadyRated
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(AppLocalizations.of(context)!.ratedThisReferee),
                          )
                        : OutlinedButton.icon(
                            onPressed: onRate,
                            icon: const Icon(Icons.star_outline, size: 18),
                            label: Text(AppLocalizations.of(context)!.rateRefereePerformance),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
