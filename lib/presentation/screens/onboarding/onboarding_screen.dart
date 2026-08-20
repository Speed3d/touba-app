import 'package:flutter/material.dart';
import '../../../data/services/preferences_service.dart';
import '../auth/auth_wrapper.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

import '../../widgets/core/decorated_background.dart';

/// 📝 HINT AR: شاشات التعريف — تُعرض مرة واحدة عند أول تشغيل. عند الإنهاء
/// نحفظ العلم في PreferencesService وننتقل لـ AuthWrapper.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  List<_OnboardData> _getPages(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      _OnboardData(Icons.groups, loc.formYourTeam, loc.formYourTeamDesc),
      _OnboardData(Icons.emoji_events, loc.organizeTournaments, loc.organizeTournamentsDesc),
      _OnboardData(Icons.insights, loc.trackStats, loc.trackStatsDesc),
    ];
  }

  void _finish() {
    PreferencesService.setOnboardingSeen();
    Navigator.of(context).pushReplacement(
      ToobaRoute.replacement(const AuthWrapper()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages(context);
    final theme = Theme.of(context);
    final isLast = _index == pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBackground(
        showOrbs: true,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _finish,
                child: Text(AppLocalizations.of(context)!.skip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon,
                              size: 88, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(p.title,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(height: 1.7, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? theme.colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isLast ? AppLocalizations.of(context)!.startNow : AppLocalizations.of(context)!.next,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardData(this.icon, this.title, this.body);
}
