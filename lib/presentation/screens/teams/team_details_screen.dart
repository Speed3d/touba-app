import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/team/team_state.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch detailed info
    context.read<TeamCubit>().fetchTeamDetails(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = context.watch<AuthCubit>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    return BlocConsumer<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is TeamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is TeamLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is TeamDetailsLoaded && state.team.id == widget.teamId) {
          final team = state.team;
          final players = state.players;
          
          final captain = players.firstWhere(
            (p) => p.id == team.captainId, 
            orElse: () => players.first // Fallback if captain not loaded correctly
          );

          // Check if current user is the captain
          final isMyTeam = currentUser != null && team.captainId == currentUser.id;
          
          // Check if user is a player and has NO team
          final canJoin = currentUser != null && 
                          currentUser.role == 'player' && 
                          (currentUser.teamId == null || currentUser.teamId!.isEmpty);

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(team.name),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Team Logo & Name Header
                  Center(
                    child: Hero(
                      tag: 'team_logo_${team.id}',
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: team.logoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: team.logoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.shield, size: 60),
                                )
                              : Icon(Icons.shield, size: 60, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    team.name,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(team.city, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(context, 'لعب', team.stats.played.toString()),
                      _buildStatCard(context, 'فاز', team.stats.won.toString()),
                      _buildStatCard(context, 'نقاط', team.stats.points.toString()),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Join Button
                  if (canJoin)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<TeamCubit>().requestToJoinTeam(team.id, currentUser.id);
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('طلب انضمام للفريق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  
                  if (isMyTeam)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to Team Settings / Manage Requests
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('إدارة الفريق ستتوفر قريباً')),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('إدارة الفريق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  
                  if (canJoin || isMyTeam) const SizedBox(height: 32),

                  // Roster (Players List)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'تشكيلة الفريق',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Captain Card
                  _buildPlayerCard(context, captain, isCaptain: true),
                  
                  // Players Cards
                  ...players.where((p) => p.id != team.captainId).map((p) => _buildPlayerCard(context, p)),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: const Center(child: Text('جاري تحميل تفاصيل الفريق...')),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, var player, {bool isCaptain = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ImageProvider? imageProvider;
    if (player.profileImage != null && player.profileImage!.isNotEmpty) {
      if (player.profileImage!.startsWith('assets/')) {
        imageProvider = AssetImage(player.profileImage!);
      } else {
        imageProvider = CachedNetworkImageProvider(player.profileImage!);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Row(
          children: [
            Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isCaptain) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('كابتن', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
        subtitle: Text(player.position ?? 'لاعب'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(player.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
