import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/tournament_model.dart';
import '../models/referee_application_model.dart';

/// 📝 HINT AR: التعامل مع مجموعة البطولات. الترتيب (standings) يكتبه النظام (CF).
class TournamentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  TournamentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createTournament(TournamentModel tournament) async {
    await _firestore
        .collection('tournaments')
        .doc(tournament.id)
        .set(tournament.toJson());
  }

  // 📝 HINT AR: رفع صورة البطولة (cover/cup) — مسار tournaments/{id}/... .
  Future<String> uploadTournamentImage(String tournamentId, File file,
      {String name = 'cover'}) async {
    final ref = _storage.ref().child('tournaments/$tournamentId/$name.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  // 📝 HINT AR: تحديث حقول البطولة (للأدمن — الاسم/الصور/الجوائز/الراعي).
  Future<void> updateTournament(
      String tournamentId, Map<String, dynamic> data) async {
    await _firestore.collection('tournaments').doc(tournamentId).update(data);
  }

  // 📝 HINT AR: ترقيم صفحات بسيط (limit) لترشيد الاستهلاك.
  Future<List<TournamentModel>> getTournaments({int limit = 50}) async {
    final snap =
        await _firestore.collection('tournaments').limit(limit).get();
    return snap.docs
        .map((d) => TournamentModel.fromJson(d.data(), d.id))
        .toList();
  }

  Future<TournamentModel> getTournamentById(String id) async {
    final doc = await _firestore.collection('tournaments').doc(id).get();
    if (!doc.exists) throw Exception('البطولة غير موجودة');
    return TournamentModel.fromJson(doc.data()!, doc.id);
  }

  // ─── طلبات التحكيم (Referee Applications) ────────────────────────────

  // 📝 HINT AR: تقديم طلب تحكيم لبطولة (يستلمه الأدمن). يُقدَّم مرة واحدة: نمنع
  // التكرار إن كان هناك طلب pending أو approved (الوجبة 7 — النقطة 3). بعد الرفض
  // يُسمح بإعادة التقديم (طلب rejected لا يحجب).
  Future<void> applyAsReferee({
    required String userId,
    required String userName,
    required String userPhone,
    required TournamentModel tournament,
  }) async {
    final existing = await _firestore
        .collection('referee_applications')
        .where('userId', isEqualTo: userId)
        .where('tournamentId', isEqualTo: tournament.id)
        .where('status', whereIn: ['pending', 'approved'])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final status = existing.docs.first.data()['status'];
      throw Exception(status == 'approved'
          ? 'تمت الموافقة على تحكيمك في هذه البطولة مسبقاً'
          : 'لديك طلب تحكيم قيد المراجعة لهذه البطولة');
    }
    await _firestore.collection('referee_applications').add({
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'tournamentId': tournament.id,
      'tournamentName': tournament.name,
      'organizerUid': tournament.organizerUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 📝 HINT AR: بثّ طلبات التحكيم المعلّقة (لشاشة الأدمن).
  Stream<List<RefereeApplicationModel>> pendingApplicationsStream() {
    return _firestore
        .collection('referee_applications')
        .where('status', isEqualTo: 'pending')
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RefereeApplicationModel.fromJson(d.data(), d.id))
            .toList());
  }

  // 📝 HINT AR: بطولات شارك بها هذا الفريق (لعرض مركزه ونقاطه في كل بطولة).
  // array-contains على teamIds (يحتاج فهرس مفرد تلقائي).
  Future<List<TournamentModel>> getTournamentsByTeam(String teamId,
      {int limit = 30}) async {
    final snap = await _firestore
        .collection('tournaments')
        .where('teamIds', arrayContains: teamId)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => TournamentModel.fromJson(d.data(), d.id))
        .toList();
  }
}
