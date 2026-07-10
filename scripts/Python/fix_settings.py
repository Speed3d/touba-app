import re

with open('lib/presentation/screens/settings/settings_screen.dart', 'r') as f:
    content = f.read()

# Replace _card(
old_card = r"Widget _card\(BuildContext context, bool isDark, List<Widget> children\) =>\s*Material\([^;]+;"
new_card = """Widget _card(BuildContext context, bool isDark, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: children),
        ),
      );"""

content = re.sub(old_card, new_card, content, flags=re.DOTALL)

with open('lib/presentation/screens/settings/settings_screen.dart', 'w') as f:
    f.write(content)

