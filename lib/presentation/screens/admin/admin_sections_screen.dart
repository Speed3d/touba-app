import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: التحكّم بإظهار/إخفاء أقسام التطبيق (علم الميزات). يكتب الأدمن في
/// `settings/features`، وتقرؤه الشاشات (مثل main_screen لتبويب البطولات).
class AdminSectionsScreen extends StatelessWidget {
  const AdminSectionsScreen({super.key});

  Future<void> _setFlag(
      BuildContext context, String key, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('features')
          .set({key: value, 'updatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError(l10n.failedToSaveSettings));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminSectionsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('features')
              .snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};
            final tournamentsEnabled =
                data['tournamentsEnabled'] as bool? ?? true;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.emoji_events),
                    title: Text(AppLocalizations.of(context)!.tournamentsSection),
                    subtitle: Text(
                        AppLocalizations.of(context)!.showHideTournaments),
                    value: tournamentsEnabled,
                    onChanged: (v) =>
                        _setFlag(context, 'tournamentsEnabled', v),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
