import re

with open('lib/presentation/screens/teams/team_details_screen.dart', 'r') as f:
    content = f.read()

# Replace Card(
#       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
#       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
#       color: isDark ? const Color(0xFF1A3050) : Colors.white,

card_pattern = r"Card\(\s*(?:margin:[^,]+,)?\s*(?:shape:[^,]+,)?\s*(?:color:[^,]+,)?\s*child:\s*(Padding\(|Column\(|Row\()"

def replacer(match):
    child = match.group(1)
    return f"""Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      child: {child}"""

content = re.sub(card_pattern, replacer, content)

with open('lib/presentation/screens/teams/team_details_screen.dart', 'w') as f:
    f.write(content)

