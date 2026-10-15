import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

/// خدمة الإشعارات — FCM (push) + Local Notifications (foreground) + Firestore stream.
///
/// الاستخدام: NotificationService.instance.initialize() في main() بعد Firebase.initializeApp().
/// الخدمة تحفظ رمز FCM في users/{uid}.fcmTokens (مصفوفة) لدعم أجهزة متعددة.
/// Cloud Functions تقرأ هذه الرموز لإرسال push عند الأحداث (قبول/رفض طلب انضمام...).
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  final _tapController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTapped => _tapController.stream;

  bool _initialized = false;

  static const _channelId = 'touba_notifications';
  static const _channelName = 'إشعارات طوبة';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _setupLocalNotifications();
    await _requestPermissions();
    _setupFCMListeners();
  }

  Future<void> _setupLocalNotifications() async {
    if (kIsWeb) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _tapController.add(data);
          } catch (_) {
            _tapController.add({'payload': response.payload});
          }
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'إشعارات منصة طوبة لكرة القدم',
          importance: Importance.high,
        ));
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  void _setupFCMListeners() {
    // Foreground FCM messages → show local notification + تحديث عدّاد الجرس
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      // 📝 HINT AR: إشعار جديد وصل والتطبيق مفتوح — نُحدّث بادج الجرس فوراً.
      refreshUnreadCount();
    });

    // النقر على الإشعار والتطبيق بالخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data.isNotEmpty) {
        _tapController.add(message.data);
      }
    });

    // النقر على الإشعار والتطبيق مغلق تماماً (Terminated)
    _fcm.getInitialMessage().then((message) {
      if (message != null && message.data.isNotEmpty) {
        _tapController.add(message.data);
      }
    });

    // Token refresh — save updated token
    _fcm.onTokenRefresh.listen((token) async {
      final uid = _auth.currentUser?.uid;
      if (uid != null) await _saveToken(uid, token);
    });

    // Auth change — save token + seed unread badge عند تسجيل الدخول
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveTokenForUser(user.uid);
        await refreshUnreadCount();
      } else {
        _unreadCountController.add(0);
      }
    });
  }

  Future<void> _saveTokenForUser(String uid) async {
    try {
      final token = await _fcm
          .getToken()
          .timeout(const Duration(seconds: 20), onTimeout: () => null);
      if (token != null) await _saveToken(uid, token);
    } catch (_) {}
  }

  // معالجة سباق أول تسجيل: مستند المستخدم قد يُنشأ بعد التوكن بثوانٍ — نعيد المحاولة.
  Future<void> _saveToken(String uid, String token, {int attempt = 0}) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        if (attempt < 5) {
          await Future.delayed(const Duration(seconds: 3));
          return _saveToken(uid, token, attempt: attempt + 1);
        }
        return;
      }
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {}
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final n = message.notification;
    if (n == null) return;
    await _localNotifications.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  // ── Firestore CRUD ────────────────────────────────────────────────────────

  Stream<List<NotificationModel>> getNotificationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromFirestore(d))
          .toList();
      _unreadCountController.add(list.where((n) => !n.isRead).length);
      return list;
    });
  }

  Future<void> refreshUnreadCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _unreadCountController.add(0);
      return;
    }
    try {
      final count = await _db
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      _unreadCountController.add(count.count ?? 0);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
    refreshUnreadCount();
  }

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    _unreadCountController.add(0);
  }

  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
    refreshUnreadCount();
  }
}
