import re

def style_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Make sure we have the AppColors import
    if "import '../../../app/theme/app_colors.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", 
                                  "import 'package:flutter/material.dart';\nimport '../../../app/theme/app_colors.dart';")

    # The issue with challenges_screen and tournament_matches_screen is the use of `Card()` without decoration, and `Colors.grey[200]`
    
    # We want to replace standard `Card(...)` with a Container matching FotMob
    # Let's just regex replace `Card(\s*margin:.*?,)?\s*(shape:.*?,)?\s*child:\s*Padding\(\s*padding:.*?,` 
    # Actually, it's easier to just replace `Card(` with `Container( decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A2A3A) : Colors.grey[200]!)),`
    # But Card takes `child:` not `child:` directly if there's padding or shape.

    pass

style_file('lib/presentation/screens/challenges/challenges_screen.dart')

