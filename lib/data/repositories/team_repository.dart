import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/team_model.dart';
import '../models/join_request_model.dart';

/// 📝 HINT AR: التعامل مع مجموعة الفرق و رفع الشعارات وطلبات الانضمام.
class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').doc(team.id).set(team.toJson());
    } catch (e) {
      throw Exception('حدث خطأ أثناء إنشاء الفريق');
    }
  }

  // 📝 HINT AR: تحديث رابط الشعار بعد رفعه (يُستدعى بعد إنشاء مستند الفريق).
  Future<void> updateTeamLogo(String teamId, String logoUrl) async {
    await _firestore.collection('teams').doc(teamId).update({'logoUrl': logoUrl});
  }

  // 📝 HINT AR: هل لدى هذا الكابتن فريق مسبقاً؟ (قاعدة: فريق واحد لكل كابتن).
  Future<bool> captainHasTeam(String captainId) async {
    final snap = await _firestore
        .collection('teams')
        .where('captainId', isEqualTo: captainId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // 📝 HINT AR: مسار الشعار يطابق قواعد Storage: teams/{teamId}/logo/...
  Future<String> uploadTeamLogo(String teamId, File imageFile) async {
    try {
      final ref = _storage.ref().child('teams/$teamId/logo/logo.jpg');
      final task = await ref.putFile(imageFile);
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw Exception('حدث خطأ أثناء رفع الشعار');
    }
  }

  // 📝 HINT AR: ترقيم صفحات بسيط (limit) لترشيد الاستهلاك.
  Future<List<TeamModel>> getTeams({int limit = 50}) async {
    try {
      final snap = await _firestore.collection('teams').limit(limit).get();
      return snap.docs.map((d) => TeamModel.fromJson(d.data(), d.id)).toList();
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

  // 📝 HINT AR: جلب عدة فرق بمعرّفاتها (لعرض الترتيب/الجدول). whereIn حتى 30 معرّف.
  Future<List<TeamModel>> getTeamsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _firestore
        .collection('teams')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snap.docs.map((d) => TeamModel.fromJson(d.data(), d.id)).toList();
  }

  // 📝 HINT AR: طلب انضمام — يُنشئ مستنداً في join_requests. عند قبول الكابتن
  // تتولّى Cloud Function `onJoinRequestAccepted` إنشاء سجل لاعب مرتبط بالحساب.
  Future<void> requestToJoin(
      String teamId, String userId, String userName) async {
    try {
      await _firestore.collection('join_requests').add({
        'teamId': teamId,
        'userId': userId,
        'userName': userName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء إرسال الطلب');
    }
  }

  // 📝 HINT AR: طلبات الانضمام المعلّقة لفريق (يقرؤها كابتنه — قواعد الأمان).
  Future<List<JoinRequestModel>> getPendingJoinRequests(String teamId) async {
    try {
      final snap = await _firestore
          .collection('join_requests')
          .where('teamId', isEqualTo: teamId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => JoinRequestModel.fromJson(d.data(), d.id))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب طلبات الانضمام');
    }
  }

  // 📝 HINT AR: قبول/رفض طلب — القبول يُشغّل Cloud Function لإنشاء سجل اللاعب.
  Future<void> setJoinRequestStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection('join_requests')
          .doc(requestId)
          .update({'status': status});
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث الطلب');
    }
  }
}
