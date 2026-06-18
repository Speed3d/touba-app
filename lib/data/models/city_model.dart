import 'package:cloud_firestore/cloud_firestore.dart';

/// 📝 HINT AR: نموذج المحافظة/المدينة (City Model)
///
/// يمثل المحافظة لدعم تعدد اللغات والتفعيل/التعطيل.
class CityModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final int order;
  final bool isActive;

  CityModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.order = 0,
    this.isActive = true,
  });

  factory CityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CityModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? data['name'] ?? '',
      nameEn: data['nameEn'] ?? data['name'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'order': order,
      'isActive': isActive,
    };
  }

  CityModel copyWith({
    String? nameAr,
    String? nameEn,
    int? order,
    bool? isActive,
  }) {
    return CityModel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// 📝 HINT AR: Helper للحصول على الاسم باللغة العربية كافتراضي (أو الإنجليزية مستقبلاً).
extension CityModelLocale on CityModel {
  String get name => nameAr.isNotEmpty ? nameAr : nameEn;
}
