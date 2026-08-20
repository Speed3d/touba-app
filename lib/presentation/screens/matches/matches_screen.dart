import '../../../core/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/tournament_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'tournament_matches_screen.dart';
import '../../../app/router/tooba_route.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/theme/app_colors.dart';
import '../../widgets/core/decorated_background.dart';

/// 📝 HINT AR: شاشة المباريات بتصميم FotMob. تتيح التبديل بين عرض البطولات أو جميع المباريات.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  bool _showAllMatches = false;
  late Future<List<TournamentModel>> _tournamentsFuture;
  late Future<List<MatchModel>> _matchesFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _tournamentsFuture = context.read<TournamentRepository>().getTournaments();
    _matchesFuture = context.read<MatchRepository>().getAllMatches(limit: 100);
  }

  Future<void> _reload() async {
    setState(() {
      _loadData();
    });
    if (_showAllMatches) {
      await _matchesFuture;
    } else {
      await _tournamentsFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${AppLocalizations.of(context)!.matches} ⚽',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: isDark ? Colors.white : Colors.black87)),
            // Toggle
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  _toggleBtn(AppLocalizations.of(context)!.tournamentsTab, !_showAllMatches, isDark),
                  _toggleBtn(AppLocalizations.of(context)!.matchesTab, _showAllMatches, isDark),
                ],
              ),
            ),
          ],
        ),
        bottom: _showAllMatches
            ? TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00D166),
                labelColor: isDark ? Colors.white : Colors.black87,
                unselectedLabelColor: isDark ? const Color(0xFF6A8898) : Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.liveTab),
                  Tab(text: AppLocalizations.of(context)!.upcomingTab),
                  Tab(text: AppLocalizations.of(context)!.finishedTab),
                ],
              )
            : null,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: _showAllMatches ? _buildAllMatches(isDark) : _buildTournaments(isDark),
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllMatches = text == AppLocalizations.of(context)!.matchesTab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? (isDark ? const Color(0xFF1A3050) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: active
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? const Color(0xFF6A8898) : Colors.grey))),
      ),
    );
  }

  // ── عرض البطولات ────────────────────────────────────────────────────────
  Widget _buildTournaments(bool isDark) {
    return FutureBuilder<List<TournamentModel>>(
      future: _tournamentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerList(count: 5, tileHeight: 110);
        }
        if (snapshot.hasError) {
          return ToobaEmptyState(
            icon: Icons.wifi_off_rounded,
            title: AppLocalizations.of(context)!.failedToLoadTournaments,
            subtitle: snapshot.error.toString(),
            actionLabel: AppLocalizations.of(context)!.retry,
            onAction: _reload,
          );
        }
        final tournaments = snapshot.data ?? [];
        if (tournaments.isEmpty) {
          return ToobaEmptyState(
            icon: Icons.emoji_events,
            title: AppLocalizations.of(context)!.noTournaments,
            subtitle: AppLocalizations.of(context)!.noTournamentsFound,
          );
        }

        final ongoing = tournaments.where((t) => t.status == 'ongoing').toList();
        final finished = tournaments.where((t) => t.status == 'finished').toList();
        final others = tournaments.where((t) => t.status != 'ongoing' && t.status != 'finished').toList();

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (ongoing.isNotEmpty) ...[
                _header(AppLocalizations.of(context)!.ongoingTournaments, isDark),
                ...ongoing.map((t) => _tournamentCard(t, isDark)),
                const SizedBox(height: 8),
              ],
              if (others.isNotEmpty) ...[
                _header(AppLocalizations.of(context)!.upcomingTournaments, isDark),
                ...others.map((t) => _tournamentCard(t, isDark)),
                const SizedBox(height: 8),
              ],
              if (finished.isNotEmpty) ...[
                _header(AppLocalizations.of(context)!.finishedTournaments, isDark),
                ...finished.map((t) => _tournamentCard(t, isDark)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _header(String title, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87)),
      );

  Widget _tournamentCard(TournamentModel t, bool isDark) {
    final finished = t.status == 'finished';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          ToobaRoute.to(TournamentMatchesScreen(tournament: t)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF1A3050), Color(0xFF0D1826)])
                : const LinearGradient(colors: [Color(0xFFE6F0FF), Colors.white]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1A3050) : Colors.grey[100],
                  image: t.logoUrl != null
                      ? DecorationImage(
                          image: ImageHelper.getProvider(t.logoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: t.logoUrl == null ? const Center(child: Text('🏆', style: TextStyle(fontSize: 28))) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: finished ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF00D166).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(finished ? AppLocalizations.of(context)!.statusFinished : AppLocalizations.of(context)!.statusOngoing,
                          style: TextStyle(
                              color: finished ? (isDark ? Colors.white54 : Colors.black54) : const Color(0xFF00D166),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(t.name,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${t.city} • ${AppLocalizations.of(context)!.teamsCountText(t.teamIds.length)}',
                        style: TextStyle(
                            color: isDark ? const Color(0xFF6A8898) : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isDark ? const Color(0xFF6A8898) : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── عرض جميع المباريات (Tabs) ───────────────────────────────────────────
  Widget _buildAllMatches(bool isDark) {
    return FutureBuilder<List<MatchModel>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerList(count: 5, tileHeight: 90);
        }
        if (snapshot.hasError) {
          return ToobaEmptyState(
            icon: Icons.error_outline,
            title: AppLocalizations.of(context)!.errorTitle,
            subtitle: snapshot.error.toString(),
            onAction: _reload,
          );
        }
        final matches = snapshot.data ?? [];
        final live = matches.where((m) => m.status == 'live').toList();
        final upcoming = matches.where((m) => m.status == 'upcoming').toList();
        final finished = matches.where((m) => m.status == 'finished').toList();

        return TabBarView(
          controller: _tabController,
          children: [
            _matchList(live, isDark, true),
            _matchList(upcoming, isDark, false),
            _matchList(finished, isDark, false),
          ],
        );
      },
    );
  }

  Widget _matchList(List<MatchModel> matches, bool isDark, bool isLive) {
    if (matches.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noMatchesFound,
            style: TextStyle(color: isDark ? const Color(0xFF6A8898) : Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) => _fotMobMatchCard(matches[index], isDark, isLive),
      ),
    );
  }

  Widget _fotMobMatchCard(MatchModel m, bool isDark, bool isLive) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1826) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(m.homeTeamName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.right),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (m.status == 'finished' || m.status == 'live')
                    Text('${m.homeScore} - ${m.awayScore}',
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
                          const Icon(Icons.circle, color: Color(0xFFFF4B4B), size: 6),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context)!.liveTab,
                              style: const TextStyle(
                                  color: Color(0xFFFF4B4B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (m.dateTime != null)
                    Text(dateFormat.format(m.dateTime!),
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF6A8898) : Colors.grey)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m.awayTeamName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.left),
              ),
            ],
          ),
          // 📝 HINT AR: مسجلو الأهداف يمكن عرضهم هنا لو توفرت البيانات
        ],
      ),
    );
  }
}
