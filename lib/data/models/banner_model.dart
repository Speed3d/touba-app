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
  final String? city; // المحافظة
  final String? area; // المنطقة
  final String? phone;
  final String? whatsapp;
  final String? facebook;
  final String? instagram;
  final List<String> extraImages; // صور إضافية في شاشة التفاصيل
  final bool isActive;
  final int order; // الأقل يظهر أولاً
  final DateTime? createdAt;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.description,
    this.targetUrl,
    this.city,
    this.area,
    this.phone,
    this.whatsapp,
    this.facebook,
    this.instagram,
    this.extraImages = const [],
    this.isActive = true,
    this.order = 0,
    this.createdAt,
  });

  // 📝 HINT AR: هل للإعلان تفاصيل إضافية تستحق فتح شاشة التفاصيل؟
  bool get hasDetails =>
      (description != null && description!.isNotEmpty) ||
      (city != null && city!.isNotEmpty) ||
      (area != null && area!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty) ||
      (whatsapp != null && whatsapp!.isNotEmpty) ||
      (facebook != null && facebook!.isNotEmpty) ||
      (instagram != null && instagram!.isNotEmpty) ||
      extraImages.isNotEmpty;

  factory BannerModel.fromJson(Map<String, dynamic> json, String id) {
    return BannerModel(
      id: id,
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'],
      description: json['description'],
      targetUrl: json['targetUrl'],
      city: json['city'],
      area: json['area'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      extraImages: List<String>.from(json['extraImages'] ?? const []),
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
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (phone != null) 'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (facebook != null) 'facebook': facebook,
        if (instagram != null) 'instagram': instagram,
        'extraImages': extraImages,
        'isActive': isActive,
        'order': order,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  BannerModel copyWith({
    String? imageUrl,
    String? title,
    String? description,
    String? targetUrl,
    String? city,
    String? area,
    String? phone,
    String? whatsapp,
    String? facebook,
    String? instagram,
    List<String>? extraImages,
    bool? isActive,
    int? order,
  }) {
    return BannerModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      targetUrl: targetUrl ?? this.targetUrl,
      city: city ?? this.city,
      area: area ?? this.area,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      extraImages: extraImages ?? this.extraImages,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, imageUrl, title, description, targetUrl, city, area, phone,
        whatsapp, facebook, instagram, extraImages, isActive, order, createdAt,
      ];
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
