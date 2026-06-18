import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player_model.dart';

/// 📝 HINT AR: التعامل مع سجلات اللاعبين وروابط دعوة المطالبة.
class PlayerRepository {
  final FirebaseFirestore _firestore;
  PlayerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 📝 HINT AR: ينشئه الكابتن. القيم المحسوبة (careerStats) تبدأ صفراً
  // و claimedByUid فارغ — مطابقة لقواعد الأمان.
  Future<void> createPlayer(PlayerModel player) async {
    final data = player.toJson()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('players').doc(player.id).set(data);
  }

  Future<List<PlayerModel>> getPlayersByTeam(String teamId) async {
    final snap = await _firestore
        .collection('players')
        .where('currentTeamId', isEqualTo: teamId)
        .get();
    return snap.docs.map((d) => PlayerModel.fromJson(d.data(), d.id)).toList();
  }

  Future<PlayerModel> getPlayerById(String id) async {
    final doc = await _firestore.collection('players').doc(id).get();
    if (!doc.exists) throw Exception('اللاعب غير موجود');
    return PlayerModel.fromJson(doc.data()!, doc.id);
  }

  // 📝 HINT AR: تعيين اللاعب أساسياً/احتياطاً (يكتبه الكابتن — ليس حقلاً محسوباً).
  Future<void> setStarter(String playerId, bool isStarter) async {
    await _firestore.collection('players').doc(playerId).update({
      'isStarter': isStarter,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 📝 HINT AR: ينشئ رمز دعوة لمرة واحدة (صالح 7 أيام) ليطالب اللاعب بحسابه.
  // الكتابة مسموحة لكابتن الفريق فقط (قواعد claim_invites).
  Future<String> createClaimInvite(String playerId, String teamId) async {
    final token = _randomToken();
    await _firestore.collection('claim_invites').add({
      'playerId': playerId,
      'teamId': teamId,
      'token': token,
      'status': 'pending',
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return token;
  }

  String _randomToken([int len = 8]) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
