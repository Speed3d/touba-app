import 'dart:async';
import 'package:flutter/material.dart';

/// 📝 HINT AR: مؤقّت المباراة الحيّة — خادمي بالكامل: كل جهاز يحسب الدقيقة من
/// `matchStartedAt` (وقت بدء الشوط الحالي). لا حالة على الخادم سوى لحظة البدء،
/// فيبقى موحّداً ويصمد عند إغلاق التطبيق. يعرض «نهاية الشوط N» عند بلوغ المدّة.
class LiveMatchTimer extends StatefulWidget {
  final DateTime? startedAt;
  final int currentHalf;
  final int matchDuration; // دقائق لكل شوط
  final int halvesCount;
  final bool compact;

  const LiveMatchTimer({
    super.key,
    required this.startedAt,
    required this.currentHalf,
    required this.matchDuration,
    required this.halvesCount,
    this.compact = false,
  });

  @override
  State<LiveMatchTimer> createState() => _LiveMatchTimerState();
}

class _LiveMatchTimerState extends State<LiveMatchTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final started = widget.startedAt;
    final elapsedSec =
        started == null ? 0 : DateTime.now().difference(started).inSeconds;
    final minuteInHalf = elapsedSec < 0 ? 0 : (elapsedSec ~/ 60);
    final reachedEnd = minuteInHalf >= widget.matchDuration;
    final cappedInHalf =
        minuteInHalf > widget.matchDuration ? widget.matchDuration : minuteInHalf;
    final displayMinute =
        (widget.currentHalf - 1) * widget.matchDuration + cappedInHalf;

    final label = reachedEnd
        ? 'نهاية الشوط ${widget.currentHalf}'
        : "$displayMinute'";

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 10, vertical: widget.compact ? 3 : 5),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            reachedEnd ? label : 'مباشر • $label',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: widget.compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
