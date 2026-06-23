import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/player_model.dart';

/// 📝 HINT AR: التعامل مع سجلات اللاعبين.
class PlayerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  PlayerRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

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

  // 📝 HINT AR: تعديل الحقول الشخصية للاعب صاحب السجل (بعد المطالبة): القدم
  // المفضّلة/الطول/الوزن/تاريخ الميلاد/النبذة. مطابق لقاعدة `players` (changes).
  Future<void> updatePersonalDetails(
    String playerId, {
    String? preferredFoot,
    int? height,
    int? weight,
    DateTime? birthDate,
    String? bio,
  }) async {
    await _firestore.collection('players').doc(playerId).update({
      'preferredFoot': preferredFoot,
      'height': height,
      'weight': weight,
      'birthDate': birthDate?.toIso8601String(),
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 📝 HINT AR: رفع صورة معرض اللاعب — المسار يطابق قواعد Storage:
  // players/{id}/gallery/...
  Future<String> uploadGalleryImage(String playerId, File file) async {
    final name = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('players/$playerId/gallery/$name.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  // 📝 HINT AR: حفظ قائمة روابط معرض اللاعب (حتى 5).
  Future<void> setGallery(String playerId, List<String> urls) async {
    await _firestore.collection('players').doc(playerId).update({
      'gallery': urls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
