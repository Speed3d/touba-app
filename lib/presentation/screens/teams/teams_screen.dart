import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';
import 'create_team_screen.dart';
import 'team_details_screen.dart';

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
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TeamError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('حدث خطأ: ${state.message}'),
                  TextButton(
                    onPressed: () => context.read<TeamCubit>().fetchTeams(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is TeamsLoaded) {
            final filteredTeams = state.teams.where((team) {
              return team.name.toLowerCase().contains(_searchQuery) ||
                     team.city.toLowerCase().contains(_searchQuery);
            }).toList();

            if (filteredTeams.isEmpty) {
              return const Center(
                child: Text('لا توجد فرق مطابقة للبحث'),
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
                            Text(team.city, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 12),
                            Icon(Icons.group, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text('${team.playersIds.length + 1} لاعب', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamDetailsScreen(teamId: team.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: Text('لا توجد بيانات'));
        },
      ),
      floatingActionButton: isCaptain
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('تأسيس فريق'),
            )
          : null,
    );
  }
}
