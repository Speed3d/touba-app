import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 📝 HINT AR: إعلان (بانر) يُعرض في سلايدر الرئيسية. يتحكّم به الأدمن حصراً
/// (إنشاء/تعديل/تفعيل/حذف). القراءة عامة. الصور cache-first عبر cached_network_image.
class BannerModel extends Equatable {
  final String id;
  final String imageUrl;
  final String? title;
  final String? description;
  final String? targetUrl; // رابط ويب يُفتح عند النقر (اختياري)
  final bool isActive;
  final int order; // الأقل يظهر أولاً
  final DateTime? createdAt;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.description,
    this.targetUrl,
    this.isActive = true,
    this.order = 0,
    this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json, String id) {
    return BannerModel(
      id: id,
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'],
      description: json['description'],
      targetUrl: json['targetUrl'],
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (targetUrl != null) 'targetUrl': targetUrl,
        'isActive': isActive,
        'order': order,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  BannerModel copyWith({
    String? imageUrl,
    String? title,
    String? description,
    String? targetUrl,
    bool? isActive,
    int? order,
  }) {
    return BannerModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      targetUrl: targetUrl ?? this.targetUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, imageUrl, title, description, targetUrl, isActive, order, createdAt];
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
