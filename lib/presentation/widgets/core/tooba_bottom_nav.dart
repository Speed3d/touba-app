import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';

/// 📝 HINT AR: عنصر واحد في شريط التنقّل العائم.
class ToobaNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const ToobaNavItem(this.icon, this.activeIcon, this.label);
}

/// 📝 HINT AR: شريط تنقّل سفلي «عائم» بنمط طوبة المحدث. العنصر المُحدَّد يتمدّد
/// ويُظهر تسميته بحركة انزلاقية، ويدعم شارات (مثل عدّاد الرسائل).
class ToobaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ToobaNavItem> items;

  /// خريطة: فهرس العنصر ← عدد الشارة (يُعرض فقط إن > 0).
  final Map<int, int> badges;

  const ToobaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 6,
        bottom: bottomPad > 0 ? bottomPad + 6 : 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            items.length,
            (i) => _item(context, i, isDark, theme),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, bool isDark, ThemeData theme) {
    final item = items[index];
    final selected = index == currentIndex;
    final active = AppColors.primary;
    final inactive = isDark ? Colors.white60 : Colors.black54;
    final count = badges[index] ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!selected) {
          HapticFeedback.lightImpact();
          onTap(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? active.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? item.activeIcon : item.icon,
                    color: selected ? active : inactive, size: 24),
                if (count > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            width: 1.5),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(count > 9 ? '9+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            // 📝 HINT AR: النص يظهر فقط للعنصر المُحدَّد (بحركة انزلاقية).
            if (selected) ...[
              const SizedBox(width: 8),
              Text(item.label,
                  style: TextStyle(
                      color: active,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
