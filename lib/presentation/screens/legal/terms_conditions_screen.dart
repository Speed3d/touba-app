import 'package:flutter/material.dart';
import 'legal_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: الشروط والأحكام — مطلوبة للمتجرين. مسوّدة واضحة تعكس طبيعة
/// طوبة؛ راجعها قانونياً قبل النشر النهائي.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: AppLocalizations.of(context)!.termsConditionsTitle,
      lastUpdated: '17 حزيران 2026',
      intro: AppLocalizations.of(context)!.termsIntro,
      sections: [
        LegalSection(
          AppLocalizations.of(context)!.tcSec1Title,
          AppLocalizations.of(context)!.tcSec1Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec2Title,
          AppLocalizations.of(context)!.tcSec2Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec3Title,
          AppLocalizations.of(context)!.tcSec3Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec4Title,
          AppLocalizations.of(context)!.tcSec4Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec5Title,
          AppLocalizations.of(context)!.tcSec5Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec6Title,
          AppLocalizations.of(context)!.tcSec6Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec7Title,
          AppLocalizations.of(context)!.tcSec7Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec8Title,
          AppLocalizations.of(context)!.tcSec8Body,
        ),
        LegalSection(
          AppLocalizations.of(context)!.tcSec9Title,
          AppLocalizations.of(context)!.tcSec9Body,
        ),
      ],
    );
  }
}
