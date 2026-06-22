import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../../core/error/auth_exceptions.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw AuthException('حدث خطأ أثناء جلب بيانات المستخدم');
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw AuthException('حدث خطأ أثناء حفظ بيانات المستخدم');
    }
  }

  Future<bool> isPhoneNumberExists(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw AuthException('حدث خطأ أثناء التحقق من رقم الهاتف');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      throw AuthException('حدث خطأ أثناء تحديث بيانات المستخدم');
    }
  }

  // 📝 HINT AR: مسار صورة البروفايل يطابق قواعد Storage: users/{uid}/profile/...
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/profile/avatar.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw AuthException('حدث خطأ أثناء رفع الصورة الشخصية');
    }
  }

  // ==========================================
  // Admin Methods
  // ==========================================

  // 📝 HINT AR: قائمة الحكّام — مستخدمون مُنحوا صلاحية «حكم» (مرآة adminPermissions).
  Future<List<UserModel>> getReferees() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('adminPermissions', arrayContains: 'referee')
          .limit(50)
          .get();
      return query.docs.map((d) => UserModel.fromJson(d.data(), d.id)).toList();
    } catch (e) {
      throw AuthException('حدث خطأ أثناء جلب الحكّام');
    }
  }

  Future<List<UserModel>> searchUsersByPhone(String phoneQuery) async {
    try {
      // 📝 HINT AR: في Firestore البحث النصي الجزئي صعب، لذا نبحث بتطابق البداية (Prefix)
      final query = await _firestore
          .collection('users')
          .where('phone', isGreaterThanOrEqualTo: phoneQuery)
          .where('phone', isLessThanOrEqualTo: '$phoneQuery\uf8ff')
          .limit(20)
          .get();
      return query.docs.map((d) => UserModel.fromJson(d.data(), d.id)).toList();
    } catch (e) {
      throw AuthException('حدث خطأ أثناء البحث عن المستخدمين');
    }
  }
}
