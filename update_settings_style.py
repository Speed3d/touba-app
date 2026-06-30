import re
import os

files = [
    'lib/presentation/screens/settings/settings_screen.dart',
    'lib/presentation/screens/profile/profile_screen.dart',
    'lib/presentation/screens/profile/edit_profile_screen.dart'
]

for file_path in files:
    if not os.path.exists(file_path): continue
    with open(file_path, 'r') as f:
        content = f.read()

    # Add AppColors import if missing
    if "import '../../../app/theme/app_colors.dart';" not in content and "import '../../app/theme/app_colors.dart';" not in content:
        if 'screens/profile/' in file_path:
            content = content.replace("import 'package:flutter/material.dart';", 
                                      "import 'package:flutter/material.dart';\nimport '../../../app/theme/app_colors.dart';")
        else:
            content = content.replace("import 'package:flutter/material.dart';", 
                                      "import 'package:flutter/material.dart';\nimport '../../../app/theme/app_colors.dart';")
    
    # Replace background and card colors
    content = content.replace("isDark ? Colors.grey[900] : Colors.white", "isDark ? AppColors.surfaceDark : Colors.white")
    content = content.replace("isDark ? Colors.grey[900]! : Colors.grey[100]!", "isDark ? AppColors.surfaceDark : Colors.white")
    content = content.replace("isDark ? Colors.grey[800] : Colors.grey[200]", "isDark ? const Color(0xFF1A3050) : Colors.grey[200]")
    
    # In settings, remove shadow if dark mode for a sleeker FotMob look
    content = content.replace("shadowColor: Colors.black.withValues(alpha: 0.08)", "shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05)")

    with open(file_path, 'w') as f:
        f.write(content)

