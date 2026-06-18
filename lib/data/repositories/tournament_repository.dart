import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';

/// 📝 HINT AR: التعامل مع مجموعة البطولات. الترتيب (standings) يكتبه النظام (CF).
class TournamentRepository {
  final FirebaseFirestore _firestore;
  TournamentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createTournament(TournamentModel tournament) async {
    await _firestore
        .collection('tournaments')
        .doc(tournament.id)
        .set(tournament.toJson());
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
}
