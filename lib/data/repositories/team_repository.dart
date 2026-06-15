import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';

class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').doc(team.id).set(team.toJson());
      // Update the captain's teamId
      await _firestore.collection('users').doc(team.captainId).update({
        'teamId': team.id,
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء إنشاء الفريق');
    }
  }

  Future<String> uploadTeamLogo(String teamId, File imageFile) async {
    try {
      final ref = _storage.ref().child('teams/logos/$teamId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('حدث خطأ أثناء رفع الشعار');
    }
  }

  Future<List<TeamModel>> getTeams() async {
    try {
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs
          .map((doc) => TeamModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الفرق');
    }
  }

  Future<TeamModel> getTeamById(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (!doc.exists) throw Exception('الفريق غير موجود');
      return TeamModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب تفاصيل الفريق');
    }
  }

  // --- نظام طلبات الانضمام المبسط ---
  
  // اللاعب يرسل طلب انضمام
  Future<void> requestToJoin(String teamId, String userId) async {
    try {
      // Create a request document in a subcollection or separate collection
      await _firestore.collection('join_requests').add({
        'teamId': teamId,
        'userId': userId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء إرسال الطلب');
    }
  }

  // الكابتن يضيف لاعباً مباشرة أو يوافق على طلب
  Future<void> addPlayerToTeam(String teamId, String userId) async {
    try {
      // 1. Transaction to update both team and user atomically
      await _firestore.runTransaction((transaction) async {
        final teamRef = _firestore.collection('teams').doc(teamId);
        final userRef = _firestore.collection('users').doc(userId);

        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('اللاعب غير موجود');
        
        final userData = userDoc.data()!;
        if (userData['teamId'] != null && userData['teamId'] != '') {
          throw Exception('اللاعب منضم لفريق آخر بالفعل');
        }

        transaction.update(teamRef, {
          'playersIds': FieldValue.arrayUnion([userId])
        });

        transaction.update(userRef, {
          'teamId': teamId
        });
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
