import 'package:flutter/material.dart';
import '../../../app/router/tooba_route.dart';
import 'subscription_screen.dart';

/// 📝 HINT AR: ورقة سفلية تظهر عند محاولة ميزة مقفولة بالاشتراك (المرحلة 8).
/// تشرح أن الميزة تتطلّب اشتراكاً وتفتح شاشة «اشتراكي» للتفعيل/التواصل.
class SubscriptionLockedSheet extends StatelessWidget {
  final String feature;
  const SubscriptionLockedSheet({super.key, required this.feature});

  static Future<void> show(BuildContext context,
      {required String feature}) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubscriptionLockedSheet(feature: feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.workspace_premium,
                  color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text('$feature يتطلّب اشتراكاً',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'فعّل اشتراكك لفتح التحدّيات والمحادثة. التفعيل بكود من الإدارة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context, ToobaRoute.to(const SubscriptionScreen()));
                },
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: const Text('إدارة الاشتراك / تفعيل بكود'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لاحقاً')),
          ],
        ),
      ),
    );
  }
}
