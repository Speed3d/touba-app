import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 📝 HINT AR: قائمة بطاقات وهمية Shimmer تُعرض أثناء تحميل البيانات.
/// [tileHeight] ارتفاع كل بطاقة. [count] عدد البطاقات الوهمية.
class ToobaShimmerList extends StatelessWidget {
  final int count;
  final double tileHeight;
  final double tileRadius;
  final EdgeInsetsGeometry padding;

  const ToobaShimmerList({
    super.key,
    this.count = 6,
    this.tileHeight = 80,
    this.tileRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) => Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? 12 : 0),
            child: _ShimmerTile(height: tileHeight, radius: tileRadius),
          )),
        ),
      ),
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  final double height;
  final double radius;

  const _ShimmerTile({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // أيقونة / صورة
        Container(
          width: height * 0.7,
          height: height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius * 0.6),
          ),
        ),
        const SizedBox(width: 14),
        // نصوص
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  height: 11,
                  width: 140,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ),
      ],
    );
  }
}

/// بطاقة شيمر مربّعة (للبانر الكبير مثل بطولة جارية).
class ToobaShimmerBanner extends StatelessWidget {
  final double height;

  const ToobaShimmerBanner({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
