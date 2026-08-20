import 'package:flutter/material.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: قالب موحَّد لعرض المستندات القانونية (الخصوصية/الشروط) —
/// شاشة تمرير بعنوان وتاريخ تحديث وأقسام (عنوان + نص). يتكيّف مع الثيم.
class LegalScaffold extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;

  const LegalScaffold({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.lastUpdatedDate(lastUpdated),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(intro, style: const TextStyle(fontSize: 15, height: 1.7)),
              const SizedBox(height: 8),
              ...sections.map((s) => Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.heading,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(s.body,
                            style: const TextStyle(fontSize: 15, height: 1.8)),
                      ],
                    ),
                  )),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.toubaPlatform,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}
