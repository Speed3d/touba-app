import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/match_repository.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'match_detail_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: مباريات الحكم — المباريات المعيّن لها المستخدم الحالي كحكم.
/// (فصل المهام: الحكم لا يؤكّد النتيجة — يعرضها فقط؛ التأكيد للمنظّم.)
class RefereeMatchesScreen extends StatefulWidget {
  final String refereeUid;
  const RefereeMatchesScreen({super.key, required this.refereeUid});

  @override
  State<RefereeMatchesScreen> createState() => _RefereeMatchesScreenState();
}

class _RefereeMatchesScreenState extends State<RefereeMatchesScreen> {
  late Future<List<MatchModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = context
        .read<MatchRepository>()
        .getMatchesByReferee(widget.refereeUid);
  }

  Future<void> _reload() async {
    final f =
        context.read<MatchRepository>().getMatchesByReferee(widget.refereeUid);
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myRefereeMatches), centerTitle: true),
      body: FutureBuilder<List<MatchModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const ToobaShimmerList(count: 5, tileHeight: 80);
          }
          final matches = snap.data ?? [];
          if (matches.isEmpty) {
            return ToobaEmptyState(
              icon: Icons.sports_outlined,
              title: AppLocalizations.of(context)!.noMatchesAssignedToYou,
              subtitle: AppLocalizations.of(context)!.tournamentOrganizerAssignsMatches,
            );
          }
          matches.sort((a, b) {
            if (a.dateTime == null && b.dateTime == null) return 0;
            if (a.dateTime == null) return 1;
            if (b.dateTime == null) return -1;
            return a.dateTime!.compareTo(b.dateTime!);
          });
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _tile(context, matches[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, MatchModel m) {
    final theme = Theme.of(context);
    final finished = m.resultConfirmed;
    // We can use Intl directly but we can also use formatting method if needed. Let's just keep Intl since it's already there and handles dates well. Or we can just use the provided strings. We'll leave the DateFormat as is but localizing "موعد غير محدد".
    final label = finished
        ? '${m.homeScore} - ${m.awayScore}'
        : (m.dateTime != null
            ? DateFormat('EEE d MMM • HH:mm', 'ar').format(m.dateTime!)
            : AppLocalizations.of(context)!.unspecifiedDate);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: finished
            ? () => Navigator.push(
                context, ToobaRoute.to(MatchDetailScreen(match: m)))
            : null,
        leading: Icon(
          finished ? Icons.check_circle : Icons.schedule,
          color: finished ? Colors.green : theme.colorScheme.primary,
        ),
        title: Text('${m.homeTeamName} ${AppLocalizations.of(context)!.versus} ${m.awayTeamName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(AppLocalizations.of(context)!.roundX(m.round.toString())),
        trailing: Text(label,
            style: TextStyle(
                color: finished ? Colors.green : Colors.grey[600],
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
