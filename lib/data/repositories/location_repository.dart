import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/city_model.dart';
import '../models/district_model.dart';
import '../../core/constants/iraq_regions.dart';

class LocationRepository {
  final FirebaseFirestore _firestore;

  LocationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==========================================
  // Cities
  // ==========================================

  Stream<List<CityModel>> getCitiesStream({bool activeOnly = false}) {
    var query = _firestore.collection('cities').orderBy('order');
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => CityModel.fromFirestore(d)).toList());
  }

  Future<void> addCity(CityModel city) async {
    final id = city.id.isEmpty ? const Uuid().v4() : city.id;
    await _firestore
        .collection('cities')
        .doc(id)
        .set(city.toFirestore());
  }

  Future<void> updateCity(CityModel city) async {
    await _firestore.collection('cities').doc(city.id).update(city.toFirestore());
  }

  Future<void> deleteCity(String id) async {
    await _firestore.collection('cities').doc(id).delete();
    // 📝 HINT AR: يجب حذف مناطقها أيضاً
    final districts = await _firestore
        .collection('districts')
        .where('cityId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (var doc in districts.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==========================================
  // Districts
  // ==========================================

  Stream<List<DistrictModel>> getDistrictsStream(String cityId,
      {bool activeOnly = false}) {
    var query = _firestore
        .collection('districts')
        .where('cityId', isEqualTo: cityId)
        .orderBy('order');
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => DistrictModel.fromFirestore(d)).toList());
  }

  Future<void> addDistrict(DistrictModel district) async {
    final id = district.id.isEmpty ? const Uuid().v4() : district.id;
    await _firestore
        .collection('districts')
        .doc(id)
        .set(district.toFirestore());
  }

  Future<void> updateDistrict(DistrictModel district) async {
    await _firestore
        .collection('districts')
        .doc(district.id)
        .update(district.toFirestore());
  }

  Future<void> deleteDistrict(String id) async {
    await _firestore.collection('districts').doc(id).delete();
  }

  // ==========================================
  // Seeding (استيراد كل العراق)
  // ==========================================
  Future<void> seedAllIraq() async {
    final batch = _firestore.batch();
    int order = 0;

    for (final gov in IraqRegions.all) {
      // المدينة تُخزّن بحيث يكون ID هو الـ key الخاص بها لسهولة الربط
      final cityRef = _firestore.collection('cities').doc(gov.key);
      batch.set(
        cityRef,
        {
          'nameAr': gov.nameAr,
          'nameEn': gov.nameEn,
          'nameKu': gov.nameKu,
          'order': order++,
          'isActive': true,
        },
        SetOptions(merge: true),
      );

      int dOrder = 0;
      for (final dist in gov.districts) {
        final distRef = _firestore.collection('districts').doc(dist.key);
        batch.set(
          distRef,
          {
            'nameAr': dist.nameAr,
            'nameEn': dist.nameEn,
            'nameKu': dist.nameKu,
            'cityId': gov.key,
            'order': dOrder++,
            'isActive': true,
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }
}
