import re
import os

files = [
    'lib/presentation/screens/tournaments/tournament_details_screen.dart',
    'lib/presentation/screens/matches/match_detail_screen.dart',
    'lib/presentation/screens/teams/team_details_screen.dart'
]

for file_path in files:
    if not os.path.exists(file_path): continue
    with open(file_path, 'r') as f:
        content = f.read()

    # Add AppColors import if missing
    if "import '../../../app/theme/app_colors.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", 
                                  "import 'package:flutter/material.dart';\nimport '../../../app/theme/app_colors.dart';")
    
    # Replace background and card colors
    content = content.replace("isDark ? Colors.grey[900] : Colors.white", "isDark ? AppColors.surfaceDark : Colors.white")
    content = content.replace("isDark ? Colors.grey[800] : Colors.grey[200]", "isDark ? const Color(0xFF1A3050) : Colors.grey[200]")
    content = content.replace("Colors.grey[900]", "AppColors.surfaceDark")
    content = content.replace("Colors.grey[800]", "const Color(0xFF1A3050)")

    with open(file_path, 'w') as f:
        f.write(content)

