import '../../../core/utils/image_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/match_model.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: صفحة الحكم العامة (الوجبة 7 — D). تعرض الاسم/الصورة/المدينة/عدد
/// المباريات التي أدارها/متوسط التقييم/النبذة، وقائمة مبارياته. صاحب الحساب
/// يستطيع تعديل مدينته ونبذته (refereeProfiles تسمح للحكم نفسه بذلك).
class RefereeProfileScreen extends StatefulWidget {
  final String refereeUid;
  final String? refereeName; // احتياطي للعرض ريثما يُحمَّل الملف
  const RefereeProfileScreen({
    super.key,
    required this.refereeUid,
    this.refereeName,
  });

  @override
  State<RefereeProfileScreen> createState() => _RefereeProfileScreenState();
}

class _RefereeProfileScreenState extends State<RefereeProfileScreen> {
  Map<String, dynamic>? _profile;
  List<MatchModel> _matches = [];
  bool _loading = true;

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == widget.refereeUid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 📝 HINT AR: نلتقط المستودع قبل await (تفادي استخدام context عبر فجوة).
    final matchRepo = context.read<MatchRepository>();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('refereeProfiles')
          .doc(widget.refereeUid)
          .get();
      final matches = await matchRepo.getMatchesByReferee(widget.refereeUid);
      if (!mounted) return;
      setState(() {
        _profile = doc.data();
        _matches = matches;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 📝 HINT AR: عدد المباريات التي أدارها = المباريات المنتهية المعيّن لها.
  int get _matchesCount =>
      _matches.where((m) => m.resultConfirmed).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _profile ?? const {};
    final name = (p['name'] as String?) ?? widget.refereeName ?? AppLocalizations.of(context)!.referee;
    final photo = p['photoUrl'] as String?;
    final city = p['city'] as String?;
    final bio = p['bio'] as String?;
    final rating = ((p['rating'] ?? 0) as num).toDouble();
    final ratingCount = (p['ratingCount'] ?? 0) as int;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.refereeProfile),
        centerTitle: true,
        actions: [
          if (_isOwner && !_loading)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: AppLocalizations.of(context)!.editMyData,
              onPressed: () => _editProfile(city, bio),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? ImageHelper.getProvider(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Icon(Icons.sports, size: 48, color: Colors.grey[500])
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (city != null && city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(city,
                            style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // ── بطاقتا الإحصائية: عدد المباريات + التقييم ──
                Row(
                  children: [
                    Expanded(
                      child: _statCard(Icons.sports_soccer, '$_matchesCount',
                          AppLocalizations.of(context)!.matchesManaged, theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                          Icons.star,
                          ratingCount > 0
                              ? '${rating.toStringAsFixed(1)} ($ratingCount)'
                              : '—',
                          AppLocalizations.of(context)!.averageRating,
                          Colors.amber.shade700),
                    ),
                  ],
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.bioLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(bio, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.matchesList,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(AppLocalizations.of(context)!.noMatchesManaged,
                        style: TextStyle(color: Colors.grey[600])),
                  )
                else
                  ..._matches.map(_matchTile),
              ],
            ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _matchTile(MatchModel m) {
    final score = m.resultConfirmed
        ? '${m.homeScore} - ${m.awayScore}'
        : (m.status == 'live' ? AppLocalizations.of(context)!.matchLive : '—');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(m.homeTeamName,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(score,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Text(m.awayTeamName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 HINT AR: تعديل المدينة والنبذة (لصاحب الحساب فقط) — القاعدة تسمح للحكم نفسه
  // بتعديل حقوله غير المحمية (rating/ratingCount/matchesCount/verified ممنوعة).
  Future<void> _editProfile(String? city, String? bio) async {
    final cityCtrl = TextEditingController(text: city ?? '');
    final bioCtrl = TextEditingController(text: bio ?? '');
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editMyData),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityCtrl,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.city, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.bioExperience, border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.save)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('refereeProfiles')
          .doc(widget.refereeUid)
          .set({
        'city': cityCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(AppLocalizations.of(context)!.dataSavedSuccessfully));
      _load();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(ToobaSnackBar.buildError(AppLocalizations.of(context)!.failedToSave));
    }
  }
}
