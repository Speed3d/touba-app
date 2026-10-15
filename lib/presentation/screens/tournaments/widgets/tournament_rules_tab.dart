import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../../data/models/tournament_model.dart';
import '../../../../data/repositories/tournament_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cubits/tournament/tournament_cubit.dart';
import '../../../cubits/tournament/tournament_state.dart';
import '../tournament_rules_editor.dart';
import 'tournament_ad_banner_slider.dart';

/// 📝 HINT AR: تبويب «شروط وقوانين» — بانر إعلانات متحرك + نصّ الشروط/القوانين
/// + لوكوات الداعمين بحجم كبير. المنظّم/الأدمن يحرّرها عبر زر «تعديل».
class TournamentRulesTab extends StatelessWidget {
  final TournamentDetailsLoaded state;
  final bool canManage;

  const TournamentRulesTab({
    super.key,
    required this.state,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final t = state.tournament;
    final hasRules = t.rules != null && t.rules!.trim().isNotEmpty;
    final hasSponsors = t.sponsors.isNotEmpty;
    final hasBanners = t.adBanners.isNotEmpty;
    final empty = !hasRules && !hasSponsors && !hasBanners;

    return RefreshIndicator(
      onRefresh: () =>
          context.read<TournamentCubit>().fetchDetails(t.id),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (canManage) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _editRules(context, t),
                icon: const Icon(Icons.edit, size: 16),
                label: Text(AppLocalizations.of(context)!.editRulesAndSponsors),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasBanners) ...[
            TournamentAdBannerSlider(images: t.adBanners),
            const SizedBox(height: 20),
          ],
          if (hasRules) ...[
            _sectionTitle(context, AppLocalizations.of(context)!.termsAndRulesTitle, Icons.gavel),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(t.rules!, style: const TextStyle(height: 1.6)),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (hasSponsors) ...[
            _sectionTitle(context, AppLocalizations.of(context)!.sponsorsTitle, Icons.handshake),
            const SizedBox(height: 12),
            _sponsorsView(t.sponsors),
            const SizedBox(height: 20),
          ],
          if (empty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.gavel, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      canManage
                          ? AppLocalizations.of(context)!.noRulesOrSponsorsEditToAdd
                          : AppLocalizations.of(context)!.noRulesOrSponsors,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _sponsorsView(List<Sponsor> sponsors) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: sponsors
          .map((s) => SizedBox(
                width: 100,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: s.logoUrl.isNotEmpty
                          ? ImageHelper.getProvider(s.logoUrl)
                          : null,
                      child: s.logoUrl.isEmpty
                          ? const Icon(Icons.handshake, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _editRules(BuildContext context, TournamentModel t) {
    final cubit = context.read<TournamentCubit>();
    final repo = context.read<TournamentRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TournamentRulesEditor(
        tournament: t,
        repo: repo,
        onSaved: () => cubit.fetchDetails(t.id),
      ),
    );
  }
}
