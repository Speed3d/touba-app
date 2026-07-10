import re

# 1. Fix challenges_screen.dart import AppColors
with open('lib/presentation/screens/challenges/challenges_screen.dart', 'r') as f:
    c = f.read()
if "import '../../../app/theme/app_colors.dart';" not in c:
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../../app/theme/app_colors.dart';")
with open('lib/presentation/screens/challenges/challenges_screen.dart', 'w') as f:
    f.write(c)


# 2. Fix chat_screen.dart isDark in _inputBar
with open('lib/presentation/screens/chat/chat_screen.dart', 'r') as f:
    c = f.read()
if "final isDark = Theme.of(context).brightness == Brightness.dark;" not in c.split('Widget _inputBar() {')[1]:
    c = c.replace("Widget _inputBar() {", "Widget _inputBar() {\n    final isDark = Theme.of(context).brightness == Brightness.dark;")
with open('lib/presentation/screens/chat/chat_screen.dart', 'w') as f:
    f.write(c)


# 3. Fix teams_screen.dart GestureDetector issues
with open('lib/presentation/screens/teams/teams_screen.dart', 'r') as f:
    c = f.read()

# Fix the gesture detector logic. I need to cast TeamPlayerModel to PlayerModel if needed, 
# or maybe PlayerDetailScreen doesn't take PlayerModel? Let's check PlayerDetailScreen constructor again.
# Wait, let's just make it do nothing on tap for now to fix the build, or check if we can fetch the player.
