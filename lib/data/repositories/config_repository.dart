import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigRepository {
  final FirebaseFirestore _firestore;

  ConfigRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<Map<String, dynamic>> streamAppSettings() {
    return _firestore
        .collection('config')
        .doc('app_settings')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  Future<void> updateFeatureStatus(String featureKey, bool isEnabled) async {
    await _firestore.collection('config').doc('app_settings').set(
      {featureKey: isEnabled},
      SetOptions(merge: true),
    );
  }
}
