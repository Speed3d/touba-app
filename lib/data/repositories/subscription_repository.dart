import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activation_code_model.dart';

/// 📝 HINT AR: مستودع الاشتراكات (المرحلة 8). يدير **أكواد التفعيل** (توليد/قائمة
/// للأدمن) و**إعدادات الاشتراك** (settings/subscription). توليد الكود من الأدمن
/// (موثوق) بـ Random.secure؛ أمّا **الاستهلاك** فعبر Cloud Function حصراً
/// (حقول الاشتراك على users تكتبها CF فقط — جدار المصداقية).
class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  SubscriptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _codes = 'activation_codes';

  // ─── إعدادات الاشتراك ────────────────────────────────────────────────
  Future<({int freeTrialDays, bool enabled, String whatsapp})>
      getSettings() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('subscription').get();
      final d = doc.data() ?? const {};
      return (
        freeTrialDays: (d['freeTrialDays'] as num?)?.toInt() ?? 14,
        enabled: d['subscriptionEnabled'] as bool? ?? true,
        whatsapp: (d['activationWhatsapp'] as String?) ?? '',
      );
    } catch (_) {
      return (freeTrialDays: 14, enabled: true, whatsapp: '');
    }
  }

  Future<void> updateSettings(
      {int? freeTrialDays, bool? enabled, String? whatsapp}) {
    return _firestore.collection('settings').doc('subscription').set({
      if (freeTrialDays != null) 'freeTrialDays': freeTrialDays,
      if (enabled != null) 'subscriptionEnabled': enabled,
      if (whatsapp != null) 'activationWhatsapp': whatsapp,
    }, SetOptions(merge: true));
  }

  // ─── أكواد التفعيل (أدمن) ────────────────────────────────────────────
  /// توليد دفعة أكواد بمدة معيّنة. الكود = TBA-XXXX-XXXX (عشوائي تشفيري).
  Future<List<String>> generateCodes({
    required String adminId,
    required int durationMonths,
    int count = 1,
    String? notes,
  }) async {
    final batch = _firestore.batch();
    final created = <String>[];
    for (var i = 0; i < count; i++) {
      final code = _generateCode();
      final model = ActivationCodeModel(
        code: code,
        durationMonths: durationMonths,
        createdBy: adminId,
        notes: notes,
      );
      batch.set(_firestore.collection(_codes).doc(code), model.toJson());
      created.add(code);
    }
    await batch.commit();
    return created;
  }

  Stream<List<ActivationCodeModel>> streamCodes({int limit = 100}) {
    return _firestore
        .collection(_codes)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ActivationCodeModel.fromJson(d.data(), d.id))
            .toList());
  }

  Future<void> deleteCode(String code) =>
      _firestore.collection(_codes).doc(code).delete();

  Future<void> unlockCode(String code) => _firestore
      .collection(_codes)
      .doc(code)
      .update({'isLocked': false, 'failedAttempts': 0});

  // 📝 HINT AR: TBA-XXXX-XXXX من أبجدية بلا أحرف ملتبسة (O,0,1,I,L) — ~850 مليار
  // احتمال، يُولَّد بـ Random.secure (مولّد تشفيري).
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    String part() =>
        List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    return 'TBA-${part()}-${part()}';
  }
}
