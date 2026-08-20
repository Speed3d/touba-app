import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// ويدجت الخلفية المزخرفة الموحدة لتطبيق طوبة (الھوية الجديدة)
/// يعرض خلفية رياضية أنيقة مع دوائر مضيئة ضبابية (Blurred Orbs)
/// في الزوايا العلوية والسفلية.
class DecoratedBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const DecoratedBackground({
    super.key,
    required this.child,
    this.showOrbs = true, // افتراضياً تظهر الدوائر
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // الألوان
    final bgColor = AppColors.getBackground(isDark);

    return Material(
      color: bgColor,
      type: MaterialType.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية الأساسية - لون صافي + تدرج خفي
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? const Color(0xFF14532D)
                            .withValues(alpha: 0.1) // أخضر داكن شفاف بالأعلى
                        : const Color(0xFFE7F0FD)
                            .withValues(alpha: 0.2), // أخضر/أزرق فاتح جداً
                    bgColor,
                  ],
                ),
              ),
            ),
          ),

          // الدوائر الزخرفية (تظهر فقط إذا كان showOrbs=true)
          if (showOrbs) ...[
            // دائرة علوية (لون أساسي)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight
                          .withValues(alpha: isDark ? 0.12 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // دائرة سفلية (لون ثانوي - ذهبي)
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryLight
                          .withValues(alpha: isDark ? 0.08 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],

          // المحتوى الداخلي مع SafeArea
          // طلب المالك: جميع الشاشات تكون داخل SafeArea لمنع اصطدام الأزرار بالشريط السفلي/العلوي
          SafeArea(
            bottom: true,
            top: true,
            child: child,
          ),
        ],
      ),
    );
  }
}
