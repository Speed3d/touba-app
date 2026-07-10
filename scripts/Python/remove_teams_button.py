import re

with open('lib/presentation/screens/home/home_screen.dart', 'r') as f:
    c = f.read()

# We need to remove the "الفرق" button from the _quickActionsSection.
# The button is:
#               _quickActionChip(
#                 title: 'الفرق',
#                 icon: '🛡️',
#                 isDark: isDark,
#                 onTap: () => Navigator.push(context, ToobaRoute.to(const TeamsScreen())),
#               ),

button_pattern = r"\s*_quickActionChip\(\s*title: 'الفرق',\s*icon: '🛡️',\s*isDark: isDark,\s*onTap: \(\) => Navigator\.push\(context, ToobaRoute\.to\(const TeamsScreen\(\)\)\),\s*\),"

c = re.sub(button_pattern, "", c)

with open('lib/presentation/screens/home/home_screen.dart', 'w') as f:
    f.write(c)

