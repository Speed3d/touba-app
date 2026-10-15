import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submitReport(ReportModel report) async {
    await _firestore.collection('reports').add(report.toFirestore());
  }

  Stream<List<ReportModel>> streamReports({ReportStatus? filter, int limit = 100}) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (filter != null) {
      q = q.where('status', isEqualTo: filter.name);
    }

    return q.snapshots().map(
          (snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> updateReportStatus(String id, ReportStatus status) async {
    await _firestore.collection('reports').doc(id).update({
      'status': status.name,
    });
  }
}
