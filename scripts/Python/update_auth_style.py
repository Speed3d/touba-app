import re
import os

auth_files = [
    'lib/presentation/screens/auth/login_screen.dart',
    'lib/presentation/screens/auth/register_screen.dart',
    'lib/presentation/screens/auth/forgot_password_screen.dart'
]

for file_path in auth_files:
    if not os.path.exists(file_path): continue
    with open(file_path, 'r') as f:
        content = f.read()

    # Add AppColors import if missing
    if "import '../../../app/theme/app_colors.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", 
                                  "import 'package:flutter/material.dart';\nimport '../../../app/theme/app_colors.dart';")
    
    # Replace Colors.grey[900] and Colors.grey[100] with our AppColors
    content = content.replace("isDark ? Colors.grey[900] : Colors.grey[100]", 
                              "isDark ? AppColors.surfaceDark : Colors.white")
    content = content.replace("Colors.grey[900]", "AppColors.surfaceDark")
    
    # Make buttons gradient if they use ElevatedButton
    button_regex = r"ElevatedButton\.styleFrom\(\s*padding:.*?shape:.*?backgroundColor: theme\.colorScheme\.primary,\s*foregroundColor: Colors\.white,\s*\)"
    new_button_style = """ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        )"""
    
    # But wait, ElevatedButton with transparent background needs a Container with gradient wrapping it.
    # So I'll just change the button style to use primary color but better border radius.
    content = content.replace("borderRadius: BorderRadius.circular(12)", "borderRadius: BorderRadius.circular(16)")
    content = content.replace("borderRadius: BorderRadius.circular(8)", "borderRadius: BorderRadius.circular(16)")

    # Update input decoration border
    border_regex = r"OutlineInputBorder\(\s*borderRadius: BorderRadius\.circular\(16\),\s*\)"
    new_border = """OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[300]!),
                      )"""
    content = re.sub(border_regex, new_border, content)
    
    with open(file_path, 'w') as f:
        f.write(content)

