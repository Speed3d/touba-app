import re

with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    c = f.read()

# I added `import '../players/player_detail_screen.dart';`
# Let's fix the gesture detector:

c = c.replace(
    "Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(playerId: player.id)));",
    """
    // We must fetch the PlayerModel first
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    context.read<PlayerRepository>().getPlayerById(player.id).then((pModel) {
        Navigator.pop(context);
        if (pModel != null) {
            Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: pModel)));
        } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب غير موجود')));
        }
    });
    """
)

with open('lib/presentation/screens/teams/teams_screen.dart', 'w') as f:
    f.write(c)
