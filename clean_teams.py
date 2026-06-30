import re

with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    c = f.read()

# Fix BuildContext across async gaps and unnecessary null check
old_then = r"context\.read<PlayerRepository>\(\)\.getPlayerById\(player\.playerId\)\.then\(\(pModel\) \{.*?\ScaffoldMessenger.*?\}\);"
new_then = """context.read<PlayerRepository>().getPlayerById(player.playerId).then((pModel) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: pModel)));
                  }).catchError((_) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب غير موجود')));
                  });"""

c = re.sub(old_then, new_then, c, flags=re.DOTALL)

with open('lib/presentation/screens/teams/teams_screen.dart', 'w') as f:
    f.write(c)
