import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/referee_application_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: مراجعة طلبات التحكيم (للأدمن). الموافقة تمنح صفة الحكم تلقائياً
/// (عبر Cloud Function) وتُشعر المنظّم ليضيف المتقدّم في بطولته.
class AdminRefereeApplicationsScreen extends StatelessWidget {
  const AdminRefereeApplicationsScreen({super.key});

  Future<void> _resolve(
      BuildContext context, String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('referee_applications')
          .doc(id)
          .update({'status': status});
      messenger.showSnackBar(ToobaSnackBar.buildSuccess(
          status == 'approved' ? 'تمت الموافقة ومنح صفة الحكم' : 'تم الرفض'));
    } catch (_) {
      messenger.showSnackBar(ToobaSnackBar.buildError('تعذّر تنفيذ الإجراء'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TournamentRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات التحكيم'), centerTitle: true),
      body: StreamBuilder<List<RefereeApplicationModel>>(
        stream: repo.pendingApplicationsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snap.data ?? [];
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_outlined, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('لا توجد طلبات تحكيم معلّقة',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = apps[i];
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
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.userName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(a.userPhone,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('يطلب التحكيم في: ${a.tournamentName}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _resolve(context, a.id, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red)),
                              child: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _resolve(context, a.id, 'approved'),
                              child: const Text('موافقة'),
                            ),
                          ),
                        ],
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
