import re

with open('lib/presentation/widgets/core/tooba_match_card.dart', 'r') as f:
    content = f.read()

# Make sure AppColors is imported
if "import '../../../app/theme/app_colors.dart';" not in content:
    content = content.replace("import 'tooba_card.dart';", "import 'tooba_card.dart';\nimport '../../../app/theme/app_colors.dart';")

old_build = r"@override\s*Widget build\(BuildContext context\).*?Widget _liveBadge\(\) \{"
new_build = """@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasResult = homeScore != null && awayScore != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(homeTeamName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.right),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (hasResult || isLive)
                    Text('${homeScore ?? 0} - ${awayScore ?? 0}',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: isDark ? Colors.white : Colors.black87))
                  else
                    Text('vs',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? const Color(0xFF6A8898) : Colors.grey)),
                  const SizedBox(height: 4),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF4B4B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFFFF4B4B), size: 6),
                          SizedBox(width: 4),
                          Text('مباشر',
                              style: TextStyle(
                                  color: Color(0xFFFF4B4B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (dateTime != null)
                    Text(DateFormat('MMM d, h:mm a').format(dateTime!),
                        style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF6A8898) : Colors.grey)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(awayTeamName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.left),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {"""

content = re.sub(old_build, new_build, content, flags=re.DOTALL)

with open('lib/presentation/widgets/core/tooba_match_card.dart', 'w') as f:
    f.write(content)

