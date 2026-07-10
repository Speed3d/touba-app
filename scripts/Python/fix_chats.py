import re

with open('lib/presentation/screens/chat/chats_list_screen.dart', 'r') as f:
    content = f.read()

# Replace Card( ... child: ListTile ... ) with modern containers
card_pattern = r"Card\(\s*(?:margin:[^,]+,)?\s*(?:shape:[^,]+,)?\s*(?:color:[^,]+,)?\s*child:\s*ListTile\("

def replacer(match):
    return f"""Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      child: ListTile("""

content = re.sub(card_pattern, replacer, content)

with open('lib/presentation/screens/chat/chats_list_screen.dart', 'w') as f:
    f.write(content)

