import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final String type; // 'city' or 'district'
  final String? parentId; // if type is 'district', it has a parentId pointing to a 'city'

  const LocationModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
    required this.type,
    this.parentId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json, String id) {
    return LocationModel(
      id: id,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      isActive: json['isActive'] as bool? ?? true,
      type: json['type'] as String,
      parentId: json['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'isActive': isActive,
      'type': type,
      if (parentId != null) 'parentId': parentId,
    };
  }

  LocationModel copyWith({
    String? nameAr,
    String? nameEn,
    bool? isActive,
  }) {
    return LocationModel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      isActive: isActive ?? this.isActive,
      type: type,
      parentId: parentId,
    );
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, isActive, type, parentId];
}
