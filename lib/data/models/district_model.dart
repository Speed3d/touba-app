import 'package:cloud_firestore/cloud_firestore.dart';

/// 📝 HINT AR: نموذج المنطقة (District Model)
///
/// يمثل منطقة واحدة داخل محافظة باللغات الثلاث (عربي، إنجليزي، كردي).
class DistrictModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameKu;
  final String cityId;
  final bool isActive;
  final int order;

  DistrictModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.nameKu = '',
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
      nameKu: data['nameKu'] ?? '',
      cityId: data['cityId'] ?? '',
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'nameKu': nameKu,
      'cityId': cityId,
      'isActive': isActive,
      'order': order,
    };
  }

  DistrictModel copyWith({
    String? nameAr,
    String? nameEn,
    String? nameKu,
    String? cityId,
    bool? isActive,
    int? order,
  }) {
    return DistrictModel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      nameKu: nameKu ?? this.nameKu,
      cityId: cityId ?? this.cityId,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
    );
  }
}

/// 📝 HINT AR: Helper للحصول على الاسم وفق اللغة المحددة
extension DistrictModelLocale on DistrictModel {
  String get name => nameAr.isNotEmpty ? nameAr : nameEn;

  String localizedName(String langCode) {
    if (langCode == 'ku') {
      return nameKu.isNotEmpty ? nameKu : (nameAr.isNotEmpty ? nameAr : nameEn);
    }
    if (langCode == 'en') {
      return nameEn.isNotEmpty ? nameEn : nameAr;
    }
    return nameAr.isNotEmpty ? nameAr : nameEn;
  }
}
