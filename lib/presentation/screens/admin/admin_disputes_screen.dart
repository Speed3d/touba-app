import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/models/release_request_model.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: نزاعات فكّ الارتباط — طلبات خروج رفضها الكابتن وصعّدها اللاعب.
/// الأدمن يفكّ الارتباط قسرياً بضبط الحالة=accepted (تُشغّل CF فتحرّر اللاعب).
class AdminDisputesScreen extends StatelessWidget {
  const AdminDisputesScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection('release_requests')
        .where('escalated', isEqualTo: true)
        .where('status', isEqualTo: 'rejected')
        .limit(100)
        .snapshots();
  }

  Future<void> _forceRelease(BuildContext context, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فكّ ارتباط قسري'),
        content: const Text(
            'سيُفكّ ارتباط اللاعب من فريقه الحالي ويصبح حرّاً للانضمام لفريق آخر. متابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('فكّ الارتباط'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('release_requests')
          .doc(id)
          .update({'status': 'accepted'});
      messenger.showSnackBar(
          ToobaSnackBar.buildSuccess('تم فكّ ارتباط اللاعب'));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر تنفيذ العملية'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نزاعات فكّ الارتباط'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('لا توجد نزاعات مصعّدة',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = ReleaseRequestModel.fromJson(
                  docs[i].data(), docs[i].id);
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('يطلب الخروج من فريق: ${r.teamName}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      const Text('رفض الكابتن الطلب وصعّده اللاعب للإدارة',
                          style:
                              TextStyle(fontSize: 12, color: Colors.red)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _forceRelease(context, r.id),
                          icon: const Icon(Icons.lock_open, size: 18),
                          label: const Text('فكّ الارتباط قسرياً'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
