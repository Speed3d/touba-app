import 'package:flutter/material.dart';
import 'legal_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: سياسة الخصوصية — مطلوبة لمتجري Apple وGoogle. النص مسوّدة
/// واضحة تعكس بيانات طوبة الفعلية؛ راجعها قانونياً قبل النشر النهائي.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: AppLocalizations.of(context)!.privacyPolicyTitle,
      lastUpdated: '17 حزيران 2026',
      intro: AppLocalizations.of(context)!.privacyPolicyIntro,
      sections: [
        LegalSection(
          AppLocalizations.of(context)!.ppSec1Title,
          AppLocalizations.of(context)!.ppSec1Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec2Title,
          AppLocalizations.of(context)!.ppSec2Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec3Title,
          AppLocalizations.of(context)!.ppSec3Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec4Title,
          AppLocalizations.of(context)!.ppSec4Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec5Title,
          AppLocalizations.of(context)!.ppSec5Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec6Title,
          AppLocalizations.of(context)!.ppSec6Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec7Title,
          AppLocalizations.of(context)!.ppSec7Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.ppSec8Title,
          AppLocalizations.of(context)!.ppSec8Body,
        ),
      ],
    );
  }
}
