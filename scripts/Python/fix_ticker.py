import re

with open('lib/presentation/screens/home/home_screen.dart', 'r') as f:
    c = f.read()

# Make sure we have Marquee imported
if "import 'package:marquee/marquee.dart';" not in c:
    c = c.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:marquee/marquee.dart';")

# 1. Replace _newsSection(isDark) in build with _newsTickerSection(isDark)
c = c.replace("_newsSection(isDark),", "_newsTickerSection(isDark),")

# 2. Replace the old _newsSection definition with _newsTickerSection
old_news = r"// ── قسم آخر الأخبار ─────────────────────────────────────────────────────.*?Widget _tournamentsSection"
new_news = """// ── شريط الأخبار المتحرك ───────────────────────────────────────────────
  Widget _newsTickerSection(bool isDark) {
    return FutureBuilder<bool>(
      future: Future.value(true), // We don't have a toggle for news yet, but to maintain structure
      builder: (context, _) {
        return StreamBuilder<List<NewsModel>>(
          stream: context.read<HomeRepository>().getPublishedNewsStream(limit: 5),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 48);
            }
            final newsList = snap.data ?? [];
            if (newsList.isEmpty) return const SizedBox.shrink();

            final newsText = newsList.map((n) => '📰 ${n.title}').join('   •   ');

            return GestureDetector(
              onTap: () => Navigator.push(context, ToobaRoute.to(const NewsScreen())),
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1826) : Colors.white,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('عاجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Expanded(
                      child: Marquee(
                        text: newsText,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textColor),
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        blankSpace: 50.0,
                        velocity: 30.0,
                        startPadding: 10.0,
                        pauseAfterRound: const Duration(seconds: 1),
                        accelerationDuration: const Duration(seconds: 1),
                        accelerationCurve: Curves.linear,
                        decelerationDuration: const Duration(milliseconds: 500),
                        decelerationCurve: Curves.easeOut,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  // ── قسم البطولات الجارية ─────────────────────────────────────────────────
  Widget _tournamentsSection"""

c = re.sub(old_news, new_news, c, flags=re.DOTALL)

with open('lib/presentation/screens/home/home_screen.dart', 'w') as f:
    f.write(c)
