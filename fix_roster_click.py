import re

with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    content = f.read()

# Add import for PlayerDetailScreen if not present
if "import '../players/player_detail_screen.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../players/player_detail_screen.dart';")

# Find the list tile container for players in the roster
old_roster_container = r"return Container\(\s*padding: const EdgeInsets.all\(12\),"
new_roster_container = """return GestureDetector(
                onTap: () {
                  Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(playerId: player.id)));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),"""

content = re.sub(old_roster_container, new_roster_container, content)

with open('lib/presentation/screens/teams/teams_screen.dart', 'w') as f:
    f.write(content)

