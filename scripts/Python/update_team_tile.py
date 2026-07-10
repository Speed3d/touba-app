import re

with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    content = f.read()

old_team_tile_pattern = r"Widget _teamTile\(TeamModel team, bool isDark, ThemeData theme,\s*\{bool isMine = false\}\) \{.*?(?=\s*\}\s*\n*\s*\})$"
new_team_tile = """Widget _teamTile(TeamModel team, bool isDark, ThemeData theme,
      {bool isMine = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          ToobaRoute.to(BlocProvider(
            create: (ctx) => TeamCubit(
              ctx.read<TeamRepository>(),
              ctx.read<PlayerRepository>(),
            ),
            child: TeamDetailsScreen(teamId: team.id),
          )),
        ).then((_) => _refreshMyTeam());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1826) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isMine
                  ? const Color(0xFF00D166)
                  : (isDark ? const Color(0xFF1A2A3A) : Colors.grey[300]!),
              width: isMine ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'team_logo_${team.id}',
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1A3050), Color(0xFF0A2040)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE6F0FF), Colors.white],
                        ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A4060) : Colors.grey[200]!,
                    width: 2,
                  ),
                  image: team.logoUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(team.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: team.logoUrl == null
                    ? const Center(child: Text('🛡️', style: TextStyle(fontSize: 22)))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(
                    '${team.playerCount} لاعب · ${team.city}${team.area != null && team.area!.isNotEmpty ? " • ${team.area}" : ""}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF6A8898) : Colors.black54),
                  ),
                ],
              ),
            ),
            if (!isMine)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D166).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('انضم',
                    style: TextStyle(
                        color: Color(0xFF00D166),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
          ],
        ),
      ),
    );"""

content = re.sub(old_team_tile_pattern, new_team_tile, content, flags=re.DOTALL)

with open('lib/presentation/screens/teams/teams_screen.dart', 'w') as f:
    f.write(content)

