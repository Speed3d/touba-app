import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'tournament_matches_screen.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: شاشة المباريات متمحورة حول البطولة — كروت بطولات، كل كارت يفتح
/// مبارياته الخاصة (جارية/قادمة/انتهت) دون تداخل بين البطولات.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late Future<List<TournamentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TournamentRepository>().getTournaments();
  }

  Future<void> _reload() async {
    final f = context.read<TournamentRepository>().getTournaments();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المباريات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<TournamentModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ToobaShimmerList(count: 5, tileHeight: 110);
          }
          if (snapshot.hasError) {
            return ToobaEmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'تعذّر تحميل البطولات',
              subtitle: snapshot.error.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: _reload,
            );
          }
          final tournaments = snapshot.data ?? [];
          if (tournaments.isEmpty) {
            return const ToobaEmptyState(
              icon: Icons.sports_soccer_outlined,
              title: 'لا توجد بطولات بعد',
              subtitle: 'ستظهر هنا البطولات ومبارياتها',
            );
          }
          // الجارية أولاً ثم المنتهية.
          tournaments.sort((a, b) {
            if (a.status == b.status) return 0;
            if (a.status == 'ongoing') return -1;
            if (b.status == 'ongoing') return 1;
            return 0;
          });
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, i) => _card(tournaments[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _card(TournamentModel t) {
    final finished = t.status == 'finished';
    final gradient = finished
        ? [Colors.amber.shade700, Colors.orange.shade900]
        : const [Color(0xFF1877F2), Color(0xFF0C5EBF)];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          ToobaRoute.to(TournamentMatchesScreen(tournament: t)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: (t.logoUrl != null && t.logoUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(t.logoUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.45),
                          BlendMode.darken),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(LucideIcons.trophy,
                      size: 90, color: Colors.white.withValues(alpha: 0.12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(finished ? 'منتهية' : 'جارية',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(height: 8),
                      Text(t.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${t.city} • ${t.teamIds.length} فريق',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(Icons.chevron_left, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
