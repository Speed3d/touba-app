import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/banner_model.dart';
import '../models/news_model.dart';

/// 📝 HINT AR: مستودع الرئيسية — الإعلانات (banners) والأخبار (news).
/// القراءة عامة ومرشّدة (limit + فلترة الفعّال/المنشور). الكتابة للأدمن عبر القواعد.
/// الإعجاب/المشاركة مسموحان لأي مستخدم مسجّل (حقول محددة فقط).
class HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── الإعلانات (Banners) ──────────────────────────────────────────────

  // 📝 HINT AR: البانرات الفعّالة فقط، مرتّبة بـ order (يحتاج فهرس مركّب).
  Future<List<BannerModel>> getActiveBanners({int limit = 10}) async {
    final snap = await _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => BannerModel.fromJson(d.data(), d.id))
        .toList();
  }

  // 📝 HINT AR: كل البانرات للأدمن (مرتّبة بـ order).
  Future<List<BannerModel>> getAllBanners() async {
    final snap =
        await _firestore.collection('banners').orderBy('order').get();
    return snap.docs.map((d) => BannerModel.fromJson(d.data(), d.id)).toList();
  }

  Future<String> uploadBannerImage(String bannerId, File file) async {
    final ref = _storage.ref().child('banners/$bannerId/image.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  // 📝 HINT AR: رفع صورة إضافية للإعلان باسم فريد (لشاشة التفاصيل).
  Future<String> uploadBannerExtra(
      String bannerId, File file, String name) async {
    final ref = _storage.ref().child('banners/$bannerId/$name.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<void> saveBanner(BannerModel banner) async {
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .set(banner.toJson(), SetOptions(merge: true));
  }

  Future<void> setBannerActive(String bannerId, bool active) async {
    await _firestore
        .collection('banners')
        .doc(bannerId)
        .update({'isActive': active});
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firestore.collection('banners').doc(bannerId).delete();
  }

  // ─── الأخبار (News) ───────────────────────────────────────────────────

  // 📝 HINT AR: الأخبار المنشورة، الأحدث أولاً (يحتاج فهرس مركّب).
  Future<List<NewsModel>> getPublishedNews({int limit = 20}) async {
    final snap = await _firestore
        .collection('news')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => NewsModel.fromJson(d.data(), d.id)).toList();
  }

  Future<List<NewsModel>> getAllNews() async {
    final snap = await _firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => NewsModel.fromJson(d.data(), d.id)).toList();
  }

  Future<String> uploadNewsImage(String newsId, File file) async {
    final ref = _storage.ref().child('news/$newsId/image.jpg');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<void> saveNews(NewsModel news) async {
    await _firestore
        .collection('news')
        .doc(news.id)
        .set(news.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteNews(String newsId) async {
    await _firestore.collection('news').doc(newsId).delete();
  }

  // 📝 HINT AR: إعجاب/إلغاء — تحديث حقل likes فقط (تسمح به القاعدة لأي مسجّل).
  Future<void> toggleLike(String newsId, String uid, bool like) async {
    final ref = _firestore.collection('news').doc(newsId);
    await ref.update({
      'likes': like
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  // 📝 HINT AR: زيادة عدّاد المشاركة (تحديث shareCount فقط).
  Future<void> incrementShare(String newsId) async {
    await _firestore
        .collection('news')
        .doc(newsId)
        .update({'shareCount': FieldValue.increment(1)});
  }
}
