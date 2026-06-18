import 'package:cloud_firestore/cloud_firestore.dart';

/// 📝 HINT AR: نموذج المنطقة (District Model)
///
/// يمثل منطقة واحدة داخل محافظة.
class DistrictModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String cityId;
  final bool isActive;
  final int order;

  DistrictModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cityId,
    this.isActive = true,
    this.order = 0,
  });

  factory DistrictModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DistrictModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? data['name'] ?? '',
      nameEn: data['nameEn'] ?? data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'cityId': cityId,
      'isActive': isActive,
      'order': order,
    };
  }

  DistrictModel copyWith({
    String? nameAr,
    String? nameEn,
    String? cityId,
    bool? isActive,
    int? order,
  }) {
    return DistrictModel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      cityId: cityId ?? this.cityId,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
    );
  }
}

extension DistrictModelLocale on DistrictModel {
  String get name => nameAr.isNotEmpty ? nameAr : nameEn;
}
