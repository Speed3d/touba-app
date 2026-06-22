import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';

/// 📝 HINT AR: مستودع تحدّيات الفرق الودّية (المرحلة 7). طلب مفتوح → فرق تتقدّم
/// → صاحب الطلب يختار خصماً (يُفتح chat). الترتيب محلي (بلا فهرس مركّب).
/// إشعارات التقديم/القبول عبر Cloud Functions (الطرف الآخر لا يكتب إشعاره).
class ChallengeRepository {
  final FirebaseFirestore _firestore;
  ChallengeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _col = 'challenges';
  CollectionReference<Map<String, dynamic>> get _ch =>
      _firestore.collection(_col);

  Future<void> createChallenge(ChallengeModel c) =>
      _ch.doc(c.id).set(c.toJson());

  /// 📝 HINT AR: الطلب المفتوح الحالي للكابتن (لمنع أكثر من طلب مفتوح). استعلام
  /// مساواة فقط (بلا فهرس مركّب).
  Future<ChallengeModel?> getMyOpenChallenge(String uid) async {
    final snap = await _ch
        .where('requesterCaptainId', isEqualTo: uid)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ChallengeModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  /// تعديل طلب مفتوح (الملاحظة/الموعد) — بديل عن نشر طلب جديد.
  Future<void> updateChallenge(String id,
      {required String? note, required DateTime? matchDate}) {
    return _ch.doc(id).update({
      'note': note,
      'matchDate': matchDate == null ? null : Timestamp.fromDate(matchDate),
    });
  }

  /// الطلبات المفتوحة (بثّ حيّ) — الفلترة بالمدينة/استثناء طلبي تتم في الواجهة.
  Stream<List<ChallengeModel>> streamOpen({int limit = 50}) {
    return _ch
        .where('status', isEqualTo: 'open')
        .limit(limit)
        .snapshots()
        .map(_mapSorted);
  }

  /// طلباتي (كل الحالات).
  Stream<List<ChallengeModel>> streamMine(String uid, {int limit = 50}) {
    return _ch
        .where('requesterCaptainId', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map(_mapSorted);
  }

  /// الطلبات التي تقدّمتُ إليها (arrayContains على معرّفات الكباتن المتقدّمين).
  Stream<List<ChallengeModel>> streamApplied(String uid, {int limit = 50}) {
    return _ch
        .where('applicantCaptainIds', arrayContains: uid)
        .limit(limit)
        .snapshots()
        .map(_mapSorted);
  }

  List<ChallengeModel> _mapSorted(QuerySnapshot<Map<String, dynamic>> s) {
    final list =
        s.docs.map((d) => ChallengeModel.fromJson(d.data(), d.id)).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  /// تقدّم فريق على تحدٍّ (يضيف نفسه لقائمة المتقدّمين).
  Future<void> apply(String challengeId, ChallengeApplicant a) {
    return _ch.doc(challengeId).update({
      'applicants': FieldValue.arrayUnion([a.toJson()]),
      'applicantCaptainIds': FieldValue.arrayUnion([a.captainId]),
    });
  }

  /// إلغاء الطلب (صاحبه فقط).
  Future<void> cancel(String challengeId) =>
      _ch.doc(challengeId).update({'status': 'cancelled'});

  /// قبول متقدّم (يقفل الطلب + يربط المحادثة) — يُستدعى بعد إنشاء المحادثة.
  Future<void> matchWith(
      String challengeId, ChallengeApplicant chosen, String chatId) {
    return _ch.doc(challengeId).update({
      'status': 'matched',
      'matchedTeamId': chosen.teamId,
      'matchedTeamName': chosen.teamName,
      'matchedCaptainId': chosen.captainId,
      'chatId': chatId,
    });
  }
}
