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
  }) async {
    await _firestore.collection('matches').doc(matchId).update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'events': events,
      'lineup': lineup,
      'status': 'finished',
      'resultConfirmed': true,
    });
  }
}
