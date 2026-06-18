import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../widgets/core/tooba_empty_state.dart';
import '../../widgets/core/tooba_shimmer.dart';
import 'create_team_screen.dart';
import 'team_details_screen.dart';
import '../../../app/router/tooba_route.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch teams on init if not already loaded
    final state = context.read<TeamCubit>().state;
    if (state is! TeamsLoaded) {
      context.read<TeamCubit>().fetchTeams();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = context.watch<AuthCubit>().state;
    final isCaptain = authState is AuthAuthenticated && authState.user.role == 'captain';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الفرق الشعبية'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن فريق...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<TeamCubit, TeamState>(
        builder: (context, state) {
          if (state is TeamLoading && state is! TeamsLoaded) {
            return const ToobaShimmerList(count: 7, tileHeight: 76);
          }

          if (state is TeamError) {
            return ToobaEmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'تعذّر تحميل الفرق',
              subtitle: state.message,
              actionLabel: 'إعادة المحاولة',
              onAction: () => context.read<TeamCubit>().fetchTeams(),
            );
          }

          if (state is TeamsLoaded) {
            final filteredTeams = state.teams.where((team) {
              return team.name.toLowerCase().contains(_searchQuery) ||
                     team.city.toLowerCase().contains(_searchQuery);
            }).toList();

            if (state.teams.isEmpty) {
              return ToobaEmptyState(
                icon: Icons.shield_outlined,
                title: 'لا توجد فرق مسجّلة بعد',
                subtitle: isCaptain
                    ? 'أسّس فريقك بزر «تأسيس فريق» أدناه'
                    : 'لم يُسجَّل أي فريق في المنصة بعد',
              );
            }

            if (filteredTeams.isEmpty) {
              return ToobaEmptyState(
                icon: Icons.search_off_rounded,
                title: 'لا توجد نتائج',
                subtitle: 'لا يوجد فريق يطابق "$_searchQuery"',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<TeamCubit>().fetchTeams(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredTeams.length,
                itemBuilder: (context, index) {
                  final team = filteredTeams[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? Colors.grey[900] : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Hero(
                        tag: 'team_logo_${team.id}',
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: team.logoUrl != null
                              ? CachedNetworkImageProvider(team.logoUrl!)
                              : null,
                          child: team.logoUrl == null
                              ? Icon(Icons.shield, color: isDark ? Colors.grey[600] : Colors.grey[400])
                              : null,
                        ),
                      ),
                      title: Text(
                        team.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                team.area != null && team.area!.isNotEmpty
                                    ? '${team.city} • ${team.area}'
                                    : team.city,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.group, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text('${team.playerCount} لاعب', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      onTap: () {
                        // 📝 HINT AR: نعزل TeamCubit لشاشة التفاصيل حتى لا تُفسد
                        // حالة قائمة الفرق (يصلح اختفاء الفرق عند الرجوع).
                        Navigator.push(
                          context,
                          ToobaRoute.to(BlocProvider(
                            create: (ctx) => TeamCubit(
                              ctx.read<TeamRepository>(),
                              ctx.read<PlayerRepository>(),
                            ),
                            child: TeamDetailsScreen(teamId: team.id),
                          )),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const ToobaShimmerList(count: 5, tileHeight: 76);
        },
      ),
      floatingActionButton: isCaptain
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  ToobaRoute.to(const CreateTeamScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('تأسيس فريق'),
            )
          : null,
    );
  }
}
