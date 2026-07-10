import re
import os

files = [
    'lib/presentation/screens/chat/chats_list_screen.dart',
    'lib/presentation/screens/chat/chat_screen.dart',
    'lib/presentation/screens/chat/group_chat_screen.dart'
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
    
    # Specific for chat_screen message bubbles
    # isMe ? theme.colorScheme.primary : (isDark ? Colors.grey[800] : Colors.grey[200])
    # the above is usually what's used. We just leave it as is or change Colors.grey[800] to AppColors.surfaceDark
    content = content.replace("Colors.grey[800]", "AppColors.surfaceDark")

    with open(file_path, 'w') as f:
        f.write(content)

