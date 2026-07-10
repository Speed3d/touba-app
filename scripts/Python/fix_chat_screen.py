import re

with open('lib/presentation/screens/chat/chat_screen.dart', 'r') as f:
    content = f.read()

old_bubble = r"Widget _bubble\(ChatMessageModel m\) \{.*?Widget _inputBar"
new_bubble = """Widget _bubble(ChatMessageModel m) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (m.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.transparent),
          ),
          child: Text(m.content,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
        ),
      );
    }
    final mine = _uid != null && m.isFromMe(_uid!);
    final time = m.sentAt != null ? DateFormat('HH:mm').format(m.sentAt!) : '';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF00D166).withValues(alpha: isDark ? 0.2 : 1)
              : (isDark ? AppColors.surfaceDark : Colors.grey.shade200),
          border: mine
              ? Border.all(color: isDark ? const Color(0xFF00D166).withValues(alpha: 0.5) : Colors.transparent)
              : Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.transparent),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: mine ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !mine ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(m.senderName,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[700])),
            Text(m.content,
                style: TextStyle(color: mine ? (isDark ? const Color(0xFF00D166) : Colors.white) : (isDark ? Colors.white : Colors.black87))),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    fontSize: 9,
                    color: mine ? (isDark ? const Color(0xFF00D166).withValues(alpha: 0.7) : Colors.white70) : (isDark ? Colors.grey[500] : Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _inputBar"""

content = re.sub(old_bubble, new_bubble, content, flags=re.DOTALL)

# Fix TextField filled color
content = content.replace("filled: true,", "filled: true,\n                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],")

with open('lib/presentation/screens/chat/chat_screen.dart', 'w') as f:
    f.write(content)

