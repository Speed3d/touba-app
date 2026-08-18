import 'package:flutter/material.dart';
import '../../../data/models/match_model.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: عرض شجرة خروج المغلوب (الوجبة 7). يُجمّع مباريات الإقصائي حسب
/// bracketRound في أعمدة (دور بعد دور حتى النهائي)، قابلة للتمرير أفقياً. يُبرِز
/// المتأهّل من كل مباراة. الخانات غير المحسومة تظهر «يُحدَّد لاحقاً».
class BracketView extends StatelessWidget {
  final List<MatchModel> matches; // مباريات الإقصائي فقط (stage == knockout)
  final void Function(MatchModel match)? onMatchTap;
  const BracketView({super.key, required this.matches, this.onMatchTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final knockout =
        matches.where((m) => m.stage == 'knockout').toList();
    if (knockout.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(l10n.bracketNotGeneratedYet,
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    final byRound = <int, List<MatchModel>>{};
    for (final m in knockout) {
      byRound.putIfAbsent(m.bracketRound, () => []).add(m);
    }
    final rounds = byRound.keys.toList()..sort();
    final lastRound = rounds.isEmpty ? 0 : rounds.last;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final r in rounds)
              _roundColumn(
                  context, l10n, _roundLabel(l10n, r, lastRound), byRound[r]!),
          ],
        ),
      ),
    );
  }

  Widget _roundColumn(BuildContext context, AppLocalizations l10n, String label,
      List<MatchModel> ms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          for (final m in ms) _matchCard(context, l10n, m),
        ],
      ),
    );
  }

  Widget _matchCard(BuildContext context, AppLocalizations l10n, MatchModel m) {
    // المتأهّل: advancedTeamId (للتعادل المحسوم) وإلا الأعلى نتيجةً.
    String? winnerId;
    if (m.resultConfirmed) {
      if (m.advancedTeamId != null && m.advancedTeamId!.isNotEmpty) {
        winnerId = m.advancedTeamId;
      } else if (m.homeScore != m.awayScore) {
        winnerId = m.homeScore > m.awayScore ? m.homeTeamId : m.awayTeamId;
      }
    }
    return InkWell(
      onTap: onMatchTap == null ? null : () => onMatchTap!(m),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 156,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            _teamRow(context, l10n, m.homeTeamName, m.homeScore,
                m.resultConfirmed, winnerId != null && winnerId == m.homeTeamId),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.3)),
            _teamRow(context, l10n, m.awayTeamName, m.awayScore,
                m.resultConfirmed, winnerId != null && winnerId == m.awayTeamId),
          ],
        ),
      ),
    );
  }

  Widget _teamRow(BuildContext context, AppLocalizations l10n, String name,
      int score, bool played, bool isWinner) {
    final label = name.isEmpty ? l10n.toBeDetermined : name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    color: name.isEmpty ? Colors.grey : null,
                    fontWeight:
                        isWinner ? FontWeight.bold : FontWeight.normal)),
          ),
          if (played)
            Text('$score',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWinner
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700])),
          if (isWinner) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left, size: 14, color: Colors.green),
          ],
        ],
      ),
    );
  }

  // 📝 HINT AR: تسمية الدور من موقعه من النهاية (النهائي/نصف/ربع/دور الـ16...).
  String _roundLabel(AppLocalizations l10n, int round, int lastRound) {
    final fromEnd = lastRound - round;
    switch (fromEnd) {
      case 0:
        return l10n.finalRoundName;
      case 1:
        return l10n.semiFinalName;
      case 2:
        return l10n.quarterFinalName;
      case 3:
        return l10n.roundOf16;
      case 4:
        return l10n.roundOf32;
      default:
        return l10n.knockoutRoundX(round);
    }
  }
}
