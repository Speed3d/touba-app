import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_lineup_model.dart';

/// 📝 HINT AR: مستودع تشكيلات البطولة (بند 8). الكابتن يرسل تشكيلته (status=pending)
/// والمنظّم يراجعها (approved/rejected). المعرّف ثابت `${tId}_${teamId}` لمنع
/// التكرار. الإشعارات عبر Cloud Functions (لا يكتب طرفٌ إشعار الآخر).
class TournamentLineupRepository {
  final FirebaseFirestore _firestore;
  TournamentLineupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('tournament_lineups');

  static String docId(String tournamentId, String teamId) =>
      '${tournamentId}_$teamId';

  // 📝 HINT AR: إرسال/تحديث تشكيلة الكابتن — تُعاد الحالة إلى pending للمراجعة.
  Future<void> submitLineup(TournamentLineupModel lineup) async {
    final data = lineup.toJson()..['status'] = 'pending';
    await _col.doc(lineup.id).set(data);
  }

  Future<TournamentLineupModel?> getLineup(
      String tournamentId, String teamId) async {
    final doc = await _col.doc(docId(tournamentId, teamId)).get();
    if (!doc.exists) return null;
    return TournamentLineupModel.fromJson(doc.data()!, doc.id);
  }

  // 📝 HINT AR: تشكيلات بطولة كاملة (للمنظّم للمراجعة) — استعلام مساواة واحد.
  Future<List<TournamentLineupModel>> getLineupsForTournament(
      String tournamentId) async {
    final snap =
        await _col.where('tournamentId', isEqualTo: tournamentId).get();
    return snap.docs
        .map((d) => TournamentLineupModel.fromJson(d.data(), d.id))
        .toList();
  }

  // 📝 HINT AR: مراجعة المنظّم (قبول/رفض) — يحدّث الحالة + ملاحظة اختيارية.
  Future<void> review(String lineupId, String status, {String? note}) async {
    await _col.doc(lineupId).update({
      'status': status,
      if (note != null) 'reviewNote': note,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
