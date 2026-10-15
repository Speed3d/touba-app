import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../data/models/match_model.dart';
import '../../../../l10n/app_localizations.dart';

/// 📝 HINT AR: لوحة تحكّم المباراة الحيّة للمنظّم/الأدمن — بدء المباراة، النتيجة اللحظية،
/// إنهاء الأشواط، والتأكيد النهائي.
class MatchLiveControls extends StatelessWidget {
  final MatchModel match;
  final int halves;
  final bool busy;
  final VoidCallback onStartMatch;
  final void Function(bool isHome, int delta) onScoreChange;
  final VoidCallback onConfirmHalf;
  final VoidCallback onStartNextHalf;
  final VoidCallback onOpenFinalEntry;

  const MatchLiveControls({
    super.key,
    required this.match,
    required this.halves,
    required this.busy,
    required this.onStartMatch,
    required this.onScoreChange,
    required this.onConfirmHalf,
    required this.onStartNextHalf,
    required this.onOpenFinalEntry,
  });

  @override
  Widget build(BuildContext context) {
    if (match.status == 'upcoming') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: busy ? null : onStartMatch,
          icon: const Icon(Icons.play_circle_fill),
          label: Text(AppLocalizations.of(context)!.startMatch),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
    if (match.status != 'live') return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(AppLocalizations.of(context)!.liveMatchControl,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _liveTeamStepper(match.homeTeamName, match.homeScore, true),
              Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey.withValues(alpha: 0.3)),
              _liveTeamStepper(match.awayTeamName, match.awayScore, false),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onConfirmHalf,
                icon: const Icon(Icons.flag, size: 16),
                label: Text(AppLocalizations.of(context)!.endHalfX(match.currentHalf),
                    style: const TextStyle(fontSize: 12)),
              ),
              if (match.currentHalf < halves)
                OutlinedButton.icon(
                  onPressed: busy ? null : onStartNextHalf,
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: Text(AppLocalizations.of(context)!.startHalfX(match.currentHalf + 1),
                      style: const TextStyle(fontSize: 12)),
                ),
              ElevatedButton.icon(
                onPressed: busy ? null : onOpenFinalEntry,
                icon: const Icon(Icons.sports_score, size: 16),
                label: Text(AppLocalizations.of(context)!.endAndConfirmResult,
                    style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveTeamStepper(String name, int score, bool isHome) {
    return Expanded(
      child: Column(
        children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: busy ? null : () => onScoreChange(isHome, -1),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
                visualDensity: VisualDensity.compact,
              ),
              Text('$score',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: busy ? null : () => onScoreChange(isHome, 1),
                icon: const Icon(Icons.add_circle),
                color: Colors.green,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
