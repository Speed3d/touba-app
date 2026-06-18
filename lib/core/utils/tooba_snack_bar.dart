import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class ToobaSnackBar {
  ToobaSnackBar._();

  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_outline_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_outline_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_outline_rounded);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_amber_rounded);
  }

  /// للاستخدام قبل await — يُجنّب استخدام context عبر فجوة async.
  static SnackBar buildSuccess(String message) =>
      _build(message, AppColors.success, Icons.check_circle_outline_rounded);

  static SnackBar buildError(String message) =>
      _build(message, AppColors.error, Icons.error_outline_rounded);

  static SnackBar buildInfo(String message) =>
      _build(message, AppColors.info, Icons.info_outline_rounded);

  static SnackBar buildWarning(String message) =>
      _build(message, AppColors.warning, Icons.warning_amber_rounded);

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_build(message, color, icon));
  }

  static SnackBar _build(String message, Color color, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      duration: const Duration(seconds: 3),
    );
  }
}
