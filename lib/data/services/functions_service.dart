import 'package:cloud_functions/cloud_functions.dart';

/// 📝 HINT AR: استدعاء الدوال السحابية (الجيل الثاني، منطقة europe-west1).
class FunctionsService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// ربط حساب اللاعب الحالي بسجله عبر رمز الدعوة. يُعيد معرّف السجل المرتبط.
  Future<String> claimPlayerViaInvite(String token) async {
    final callable = _functions.httpsCallable('claimPlayerViaInvite');
    final result = await callable.call(<String, dynamic>{'token': token});
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['playerId'] ?? '').toString();
  }

  /// 📝 HINT AR: ربط لاعب بكوده الدائم (الكابتن يُدخل كود اللاعب). يُعيد معرّف السجل.
  Future<String> linkPlayerByCode(String teamId, String playerCode) async {
    final callable = _functions.httpsCallable('linkPlayerByCode');
    final result = await callable.call(<String, dynamic>{
      'teamId': teamId,
      'playerCode': playerCode,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['playerId'] ?? '').toString();
  }

  /// 📝 HINT AR: منح أو سحب صلاحية من مستخدم (للأدمن فقط)
  Future<void> grantCapability(String uid, String capability, bool value) async {
    final callable = _functions.httpsCallable('grantCapability');
    await callable.call(<String, dynamic>{
      'uid': uid,
      'capability': capability,
      'value': value,
    });
  }

  /// 📝 HINT AR: إجراء أدمن على بلاغ — رد/حظر/تنبيه/تقييم سلبي/رفض.
  /// action: ban | warn | negativeRating | review | dismiss
  Future<void> moderateReport({
    required String reportId,
    required String action,
    String? adminReply,
    int? ratingPenalty,
  }) async {
    final callable = _functions.httpsCallable('moderateReport');
    await callable.call(<String, dynamic>{
      'reportId': reportId,
      'action': action,
      if (adminReply != null) 'adminReply': adminReply,
      if (ratingPenalty != null) 'ratingPenalty': ratingPenalty,
    });
  }

  /// 📝 HINT AR: تفعيل اشتراك الكابتن بكود (المرحلة 8). تحقّق خادمي + معاملة ذرّية.
  /// تُعيد {durationMonths, expiresAt} عند النجاح، وترمي FirebaseFunctionsException
  /// برسالة عربية واضحة عند الفشل (كود غير موجود/مستخدم/مقفل/تجاوز المحاولات).
  Future<Map<String, dynamic>> redeemActivationCode(String code) async {
    final callable = _functions.httpsCallable('redeemActivationCode');
    final result = await callable.call(<String, dynamic>{'code': code});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// 📝 HINT AR: يمنح التجربة المجانية للكابتن إن لم يكن له اشتراك بعد (idempotent).
  /// يُستدعى عند فتح بطاقة الاشتراك. يُعيد {granted, expiresAt}.
  Future<Map<String, dynamic>> startTrialIfEligible() async {
    final callable = _functions.httpsCallable('startTrialIfEligible');
    final result = await callable.call(<String, dynamic>{});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// 📝 HINT AR: تقييم الحكم (الوجبة 7 — النقطتان 9 و10). الفرض خادمي: المنظّم
  /// أو الأدمن أو كابتن أحد فريقَي المباراة فقط، مرة واحدة، والحكم لا يقيّم نفسه.
  /// ترمي FirebaseFunctionsException برسالة عربية واضحة عند الرفض.
  Future<void> rateReferee({
    required String matchId,
    required String refereeId,
    required int rating,
  }) async {
    final callable = _functions.httpsCallable('rateReferee');
    await callable.call(<String, dynamic>{
      'matchId': matchId,
      'refereeId': refereeId,
      'rating': rating,
    });
  }

  /// 📝 HINT AR: تذكير كابتن بإرسال تشكيلته (الوجبة 7 — بند 2). للمنظّم/الأدمن.
  Future<void> remindLineup(
      String tournamentId, String teamId, String? message) async {
    final callable = _functions.httpsCallable('remindLineup');
    await callable.call(<String, dynamic>{
      'tournamentId': tournamentId,
      'teamId': teamId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  /// 📝 HINT AR: توليد المرحلة الإقصائية يدوياً من المجموعات (احتياطي للمنظّم/
  /// الأدمن). يتولّد تلقائياً عند اكتمال المجموعات؛ هذا للطوارئ.
  Future<void> generateKnockout(String tournamentId) async {
    final callable = _functions.httpsCallable('generateKnockout');
    await callable.call(<String, dynamic>{'tournamentId': tournamentId});
  }

  /// 📝 HINT AR: حذف الحساب الحالي نهائياً (مطلوب للمتجر). تحذف الدالة:
  /// مستند المستخدم + طلبات الانضمام + فكّ ربط سجل اللاعب + حساب المصادقة.
  /// ترفض إن كان المستخدم كابتن فريق (يجب حذف/نقل الفريق أولاً).
  Future<void> deleteMyAccount() async {
    final callable = _functions.httpsCallable('deleteMyAccount');
    await callable.call(<String, dynamic>{});
  }
}
