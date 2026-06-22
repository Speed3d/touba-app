import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

/// 📝 HINT AR: التعامل مع سجلات اللاعبين.
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

  // 📝 HINT AR: تحديث صورة اللاعب (تنعكس في roster الفريق عبر syncRosterSummary).
  // يكتبها الكابتن أو اللاعب صاحب السجل (بعد المطالبة).
  Future<void> setPhoto(String playerId, String photoUrl) async {
    await _firestore.collection('players').doc(playerId).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 📝 HINT AR: تحديث مركز اللاعب (حارس/مدافع/وسط/مهاجم) — يكتبه الكابتن.
  Future<void> setPosition(String playerId, String position) async {
    await _firestore.collection('players').doc(playerId).update({
      'position': position,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 📝 HINT AR: تحديث رقم قميص اللاعب — يكتبه الكابتن (التحقق من التكرار في الكيوبت).
  Future<void> setShirtNumber(String playerId, int? number) async {
    await _firestore.collection('players').doc(playerId).update({
      'shirtNumber': number,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
