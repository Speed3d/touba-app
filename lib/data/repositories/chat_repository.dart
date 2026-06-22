import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';

/// 📝 HINT AR: مستودع المحادثات (نمط «حرفي» مُعمَّم). `chats` + `messages`
/// (subcollection)، استعلام `participants` arrayContains (بلا فهرس مركّب)،
/// عدّاد غير مقروء لكل طرف، فلترة كلمات (config/offensive_words) + rate-limit،
/// ورسالة ترحيب. البثّ الحيّ (snapshots) للمحادثة الجارية فقط (ترشيد الاستهلاك).
class ChatRepository {
  final FirebaseFirestore _firestore;
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _col = 'chats';
  static const _msgs = 'messages';

  DateTime? _lastSend; // rate-limit محلي
  List<String>? _badWords; // كاش الكلمات المحظورة (قراءة واحدة)

  // 📝 HINT AR: قائمة احتياطية صغيرة؛ الأساس قائمة الأدمن في config/offensive_words.
  static const _fallbackBadWords = ['كلب', 'حقير', 'وسخ'];

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection(_col);

  /// إنشاء/جلب محادثة بين طرفين. المعرّف ثابت (uids مرتّبة) لمنع التكرار.
  Future<String> createOrGetChat({
    required String myUid,
    required String myName,
    String? myPhoto,
    required String otherUid,
    required String otherName,
    String? otherPhoto,
    String? challengeId,
    String? welcome,
  }) async {
    final ids = [myUid, otherUid]..sort();
    final chatId = ids.join('_');
    final ref = _chats.doc(chatId);
    final doc = await ref.get();
    if (!doc.exists) {
      final now = DateTime.now();
      await ref.set({
        'participants': ids,
        'names': {myUid: myName, otherUid: otherName},
        'photos': {myUid: myPhoto, otherUid: otherPhoto},
        'unread': {myUid: 0, otherUid: 0},
        if (challengeId != null) 'challengeId': challengeId,
        'isActive': true,
        'lastMessage': welcome,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
      });
      if (welcome != null && welcome.isNotEmpty) {
        await ref.collection(_msgs).add({
          'senderId': 'system',
          'senderName': 'النظام',
          'content': welcome,
          'type': 'system',
          'sentAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return chatId;
  }

  /// محادثات المستخدم (بثّ حيّ) — مرتّبة بآخر رسالة (ترتيب محلي بلا فهرس مركّب).
  Stream<List<ChatModel>> streamUserChats(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ChatModel.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => (b.lastMessageTime ?? DateTime(2000))
          .compareTo(a.lastMessageTime ?? DateTime(2000)));
      return list;
    });
  }

  /// رسائل محادثة (بثّ حيّ، تصاعدي بالوقت).
  Stream<List<ChatMessageModel>> streamMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection(_msgs)
        .orderBy('sentAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatMessageModel.fromJson(d.data(), d.id))
            .toList());
  }

  /// عدد المحادثات التي فيها رسائل غير مقروءة (لشارة الجرس/التبويب).
  Stream<int> streamUnreadCount(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      var c = 0;
      for (final d in s.docs) {
        final u = (d.data()['unread'] as Map?)?[uid];
        if (u is num && u > 0) c++;
      }
      return c;
    });
  }

  /// إرسال رسالة نصية مع تحقّق (فراغ/طول/rate-limit/فلترة).
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) throw Exception('لا يمكن إرسال رسالة فارغة');
    if (text.length > 1000) {
      throw Exception('الرسالة طويلة جداً (الحد 1000 حرف)');
    }
    if (_lastSend != null &&
        DateTime.now().difference(_lastSend!).inMilliseconds < 800) {
      throw Exception('الرجاء الانتظار لحظة قبل إرسال رسالة أخرى');
    }
    if (await _isProhibited(text)) {
      throw Exception('الرسالة تحتوي كلمات غير لائقة');
    }
    _lastSend = DateTime.now();

    final ref = _chats.doc(chatId);
    await ref.collection(_msgs).add({
      'senderId': senderId,
      'senderName': senderName,
      'content': text,
      'type': 'text',
      'sentAt': FieldValue.serverTimestamp(),
    });

    // تحديث آخر رسالة + زيادة عدّاد غير المقروء للطرف الآخر.
    final chatDoc = await ref.get();
    final participants =
        List<String>.from(chatDoc.data()?['participants'] ?? const []);
    final updates = <String, dynamic>{
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    };
    for (final p in participants) {
      if (p != senderId) updates['unread.$p'] = FieldValue.increment(1);
    }
    await ref.update(updates);
  }

  /// تصفير عدّاد غير المقروء للمستخدم عند فتح المحادثة.
  Future<void> markAsRead(String chatId, String uid) async {
    await _chats.doc(chatId).update({'unread.$uid': 0});
  }

  Future<bool> _isProhibited(String text) async {
    if (_badWords == null) {
      try {
        final doc =
            await _firestore.collection('config').doc('offensive_words').get();
        final raw = doc.data()?['words'];
        _badWords = (raw is List && raw.isNotEmpty)
            ? List<String>.from(raw)
            : _fallbackBadWords;
      } catch (_) {
        _badWords = _fallbackBadWords;
      }
    }
    final lower = text.toLowerCase();
    return _badWords!
        .any((w) => w.isNotEmpty && lower.contains(w.toLowerCase()));
  }
}
