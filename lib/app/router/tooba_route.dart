import 'package:flutter/material.dart';

/// انتقالات صفحات موحّدة — fade + scale خفيفة (مستقلة عن اتجاه النص).
class ToobaRoute {
  ToobaRoute._();

  static const Duration _kDuration = Duration(milliseconds: 270);
  static const Duration _kReverseDuration = Duration(milliseconds: 220);

  static Route<T> to<T>(Widget screen) => _build<T>(screen);

  static Route<T> replacement<T>(Widget screen) => _build<T>(screen);

  static PageRouteBuilder<T> _build<T>(Widget screen) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: _kDuration,
      reverseTransitionDuration: _kReverseDuration,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
