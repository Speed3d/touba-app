import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 📝 HINT AR: كود تفعيل اشتراك الكابتن (المرحلة 8). يولّده الأدمن ويرسله للكابتن
/// بعد الدفع (واتساب/نقداً). المعرّف = الكود نفسه (TBA-XXXX-XXXX). الاستهلاك يتم
/// عبر Cloud Function `redeemActivationCode` حصراً (تحقّق خادمي + معاملة ذرّية).
class ActivationCodeModel extends Equatable {
  final String code; // TBA-XXXX-XXXX
  final int durationMonths; // 1 | 3 | 6 | 12
  final String createdBy; // uid الأدمن
  final DateTime? createdAt;
  final bool isUsed;
  final String? usedBy; // uid الكابتن
  final String? usedByName;
  final DateTime? usedAt;
  final String? notes;
  final bool isLocked; // قُفل بعد محاولات خاطئة متكررة
  final int failedAttempts;

  const ActivationCodeModel({
    required this.code,
    required this.durationMonths,
    required this.createdBy,
    this.createdAt,
    this.isUsed = false,
    this.usedBy,
    this.usedByName,
    this.usedAt,
    this.notes,
    this.isLocked = false,
    this.failedAttempts = 0,
  });

  String get durationLabel {
    if (durationMonths == 1) return 'شهر';
    if (durationMonths == 12) return 'سنة';
    return '$durationMonths أشهر';
  }

  String get statusText {
    if (isUsed) return 'مُستخدم';
    if (isLocked) return 'مقفل 🔒';
    return 'متاح ✅';
  }

  factory ActivationCodeModel.fromJson(Map<String, dynamic> json, String id) {
    return ActivationCodeModel(
      code: json['code'] ?? id,
      durationMonths: json['durationMonths'] ?? 1,
      createdBy: json['createdBy'] ?? '',
      createdAt: _ts(json['createdAt']),
      isUsed: json['isUsed'] ?? false,
      usedBy: json['usedBy'],
      usedByName: json['usedByName'],
      usedAt: _ts(json['usedAt']),
      notes: json['notes'],
      isLocked: json['isLocked'] ?? false,
      failedAttempts: json['failedAttempts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'durationMonths': durationMonths,
        'createdBy': createdBy,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'isUsed': isUsed,
        if (usedBy != null) 'usedBy': usedBy,
        if (usedByName != null) 'usedByName': usedByName,
        if (usedAt != null) 'usedAt': Timestamp.fromDate(usedAt!),
        if (notes != null) 'notes': notes,
        'isLocked': isLocked,
        'failedAttempts': failedAttempts,
      };

  @override
  List<Object?> get props => [
        code, durationMonths, createdBy, createdAt, isUsed, usedBy, usedByName,
        usedAt, notes, isLocked, failedAttempts,
      ];
}

DateTime? _ts(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
