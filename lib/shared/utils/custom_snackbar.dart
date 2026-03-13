import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackbarType {
  success,
  error,
  info,
}

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.success,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        bgColor = const Color(0xFF22C55E); // AppColors.onlineGreen
        icon = Icons.check_circle_rounded;
        break;
      case SnackbarType.error:
        bgColor = const Color(0xFFEF4444); // AppColors.errorRed
        icon = Icons.error_outline_rounded;
        break;
      case SnackbarType.info:
        bgColor = const Color(0xFF2463EB); // AppColors.primary
        icon = Icons.info_outline_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2535) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bgColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: bgColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
