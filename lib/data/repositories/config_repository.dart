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

  Future<bool> isTournamentsEnabled() async {
    try {
      final doc = await _firestore.collection('settings').doc('features').get();
      return doc.data()?['tournamentsEnabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  Stream<Map<String, dynamic>> streamFeatures() {
    return _firestore
        .collection('settings')
        .doc('features')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  Future<void> setFeatureFlag(String key, bool value) async {
    await _firestore.collection('settings').doc('features').set(
      {key: value, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
