import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

/// 📝 HINT AR: التعامل مع مجموعة المباريات (top-level). تأكيد النتيجة يُشغّل
/// Cloud Function `onMatchResultConfirmed` التي تحدّث الإحصائيات والترتيب ذرّياً.
class MatchRepository {
  final FirebaseFirestore _firestore;
  MatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 📝 HINT AR: إنشاء جدول المباريات دفعة واحدة (Batch) عند توليد الجدول.
  Future<void> createMatchesBatch(List<MatchModel> matches) async {
    final batch = _firestore.batch();
    for (final m in matches) {
      batch.set(_firestore.collection('matches').doc(m.id), m.toJson());
    }
    await batch.commit();
  }

  Future<List<MatchModel>> getMatchesByTournament(String tournamentId) async {
    final snap = await _firestore
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('round')
        .get();
    return snap.docs.map((d) => MatchModel.fromJson(d.data(), d.id)).toList();
  }

  Future<List<MatchModel>> getAllMatches({int limit = 50}) async {
    final snap = await _firestore.collection('matches').limit(limit).get();
    return snap.docs.map((d) => MatchModel.fromJson(d.data(), d.id)).toList();
  }

  // 📝 HINT AR: تعيين حكم لمباراة (للمنظّم/الأدمن) — يحدّث refereeId + الاسم.
  Future<void> assignReferee(
      String matchId, String? refereeId, String? refereeName) async {
    await _firestore.collection('matches').doc(matchId).update({
      'refereeId': refereeId,
      'refereeName': refereeName,
    });
  }

  // 📝 HINT AR: مباريات هذا الحكم (لشاشة «مبارياتي كحكم»).
  Future<List<MatchModel>> getMatchesByReferee(String refereeUid,
      {int limit = 50}) async {
    final snap = await _firestore
        .collection('matches')
        .where('refereeId', isEqualTo: refereeUid)
        .limit(limit)
        .get();
    return snap.docs.map((d) => MatchModel.fromJson(d.data(), d.id)).toList();
  }

  // 📝 HINT AR: تقييم الحكم بعد المباراة (1..5). مُعرّف المستند يمنع التكرار؛
  // المتوسط يُجمَّع في refereeProfiles عبر Cloud Function.
  Future<void> rateReferee({
    required String refereeId,
    required String matchId,
    required String raterId,
    required int rating,
  }) async {
    await _firestore
        .collection('referee_ratings')
        .doc('${matchId}_$raterId')
        .set({
      'refereeId': refereeId,
      'matchId': matchId,
      'raterId': raterId,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 📝 HINT AR: تقييمي السابق لحكم هذه المباراة (إن وُجد) — لعرضه مسبقاً.
  Future<int?> getMyRefereeRating(String matchId, String raterId) async {
    final doc = await _firestore
        .collection('referee_ratings')
        .doc('${matchId}_$raterId')
        .get();
    if (!doc.exists) return null;
    return doc.data()?['rating'] as int?;
  }

  // 📝 HINT AR: متوسط تقييم الحكم وعدده (من refereeProfiles).
  Future<({double rating, int count})> getRefereeProfile(
      String refereeId) async {
    final doc =
        await _firestore.collection('refereeProfiles').doc(refereeId).get();
    if (!doc.exists) return (rating: 0.0, count: 0);
    final d = doc.data()!;
    return (
      rating: ((d['rating'] ?? 0) as num).toDouble(),
      count: (d['ratingCount'] ?? 0) as int,
    );
  }

  // 📝 HINT AR: جدولة موعد المباراة (للمنظّم) — يحدّث حقل dateTime فقط.
  // الحقول الأخرى (النتيجة/statsApplied) لا تُمسّ.
  Future<void> scheduleMatch(String matchId, DateTime dateTime) async {
    await _firestore.collection('matches').doc(matchId).update({
      'dateTime': dateTime.toIso8601String(),
    });
  }

  // 📝 HINT AR: تأكيد النتيجة (للمنظّم) — يضبط resultConfirmed=true فتُشغَّل
  // الدالة السحابية التي تجمّع أحداث المباراة (الأهداف/الصناعة) في إحصائيات
  // اللاعبين. لا نلمس statsApplied (يكتبه النظام).
  Future<void> setResult(
    String matchId,
    int homeScore,
    int awayScore, {
    List<Map<String, dynamic>> events = const [],
    List<String> lineup = const [],
    // 📝 HINT AR: لقطة تشكيلة كل فريق + خطته — تُحفظ بالمباراة فتبقى ثابتة.
    List<Map<String, dynamic>> homeLineup = const [],
    List<Map<String, dynamic>> awayLineup = const [],
    String? homeFormation,
    String? awayFormation,
  }) async {
    await _firestore.collection('matches').doc(matchId).update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'events': events,
      'lineup': lineup,
      if (homeLineup.isNotEmpty) 'homeLineup': homeLineup,
      if (awayLineup.isNotEmpty) 'awayLineup': awayLineup,
      if (homeFormation != null) 'homeFormation': homeFormation,
      if (awayFormation != null) 'awayFormation': awayFormation,
      'status': 'finished',
      'resultConfirmed': true,
    });
  }
}
