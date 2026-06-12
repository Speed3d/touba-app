import 'package:cloud_firestore/cloud_firestore.dart';

/// إحداثيات مراكز المحافظات العراقية الـ18
/// المفتاح = nameAr في Firestore (مطابق تماماً لـ iraq_regions.dart)
const Map<String, ({double lat, double lon})> _iraqGovernorates = {
  'بغداد':       (lat: 33.3152, lon: 44.3661),
  'البصرة':      (lat: 30.5085, lon: 47.7804),
  'نينوى':       (lat: 36.3350, lon: 43.1189),
  'أربيل':       (lat: 36.1901, lon: 44.0119),
  'السليمانية':  (lat: 35.5570, lon: 45.4351),
  'ديالى':       (lat: 33.7464, lon: 45.2887),
  'الأنبار':     (lat: 33.4268, lon: 43.2994),
  'صلاح الدين':  (lat: 34.4655, lon: 43.4862),
  'كركوك':       (lat: 35.4681, lon: 44.3922),
  'دهوك':        (lat: 36.8680, lon: 42.9400),
  'واسط':        (lat: 32.6077, lon: 45.7147),
  'ميسان':       (lat: 31.8353, lon: 47.1460),
  'ذي قار':      (lat: 31.0575, lon: 46.2580),
  'المثنى':      (lat: 31.3113, lon: 45.2946),
  'القادسية':    (lat: 31.9858, lon: 44.9264),
  'بابل':        (lat: 32.6180, lon: 44.4222),
  'كربلاء':      (lat: 32.6160, lon: 44.0249),
  'النجف':       (lat: 31.9964, lon: 44.3262),
};

/// نتيجة عملية تحديث الإحداثيات
class CoordinatesSeedResult {
  final int updated;
  final int alreadyHad;
  final int notMatched;

  const CoordinatesSeedResult({
    required this.updated,
    required this.alreadyHad,
    required this.notMatched,
  });
}

/// تحديث إحداثيات المحافظات في Firestore
///
/// - يُحدّث latitude و longitude فقط — لا يمس الاسم ولا الـ ID ولا أي حقل آخر
/// - [overwrite] = false → يتخطى المحافظات التي لديها إحداثيات مسبقاً
/// - [overwrite] = true  → يُحدّث حتى المحافظات التي لديها إحداثيات
Future<CoordinatesSeedResult> seedCityCoordinates(
  FirebaseFirestore firestore, {
  bool overwrite = false,
}) async {
  int updated = 0;
  int alreadyHad = 0;
  int notMatched = 0;

  final citiesSnap = await firestore.collection('cities').get();

  for (final doc in citiesSnap.docs) {
    final data = doc.data();
    final nameAr = (data['nameAr'] ?? data['name'] ?? '') as String;
    final coords = _iraqGovernorates[nameAr.trim()];

    if (coords == null) {
      // لم يُطابق أي محافظة في القائمة
      notMatched++;
      continue;
    }

    final hasCoords =
        data['latitude'] != null && data['longitude'] != null;

    if (hasCoords && !overwrite) {
      alreadyHad++;
      continue;
    }

    // تحديث الإحداثيات فقط — لا شيء آخر
    await doc.reference.update({
      'latitude': coords.lat,
      'longitude': coords.lon,
    });
    updated++;
  }

  return CoordinatesSeedResult(
    updated: updated,
    alreadyHad: alreadyHad,
    notMatched: notMatched,
  );
}
