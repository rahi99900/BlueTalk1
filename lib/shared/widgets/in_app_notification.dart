import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Shows a top-slide-in in-app banner notification.
/// Call [InAppNotificationOverlay.show] from anywhere.
class InAppNotificationOverlay {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String senderName,
    required String message,
    VoidCallback? onAccept,
    VoidCallback? onTap,
  }) {
    // Remove any existing notification
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (ctx) => _FriendRequestBanner(
        senderName: senderName,
        message: message,
        onAccept: onAccept,
        onTap: onTap,
        onDismiss: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );

    overlay.insert(_entry!);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _entry?.remove();
      _entry = null;
    });
  }
}

class _FriendRequestBanner extends StatefulWidget {
  final String senderName;
  final String message;
  final VoidCallback? onAccept;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _FriendRequestBanner({
    required this.senderName,
    required this.message,
    this.onAccept,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_FriendRequestBanner> createState() => _FriendRequestBannerState();
}

class _FriendRequestBannerState extends State<_FriendRequestBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = widget.senderName.isNotEmpty ? widget.senderName[0].toUpperCase() : 'U';
    final colorVal = ((widget.senderName.codeUnitAt(0) * 8)) % 0xFFFFFF + 0xFF000000;
    final userColor = Color(colorVal).withValues(alpha: 1.0);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                widget.onTap?.call();
                _dismiss();
              },
              onVerticalDragEnd: (d) {
                if (d.primaryVelocity != null && d.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: userColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: GoogleFonts.inter(
                                color: userColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.message,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Accept button
                    if (widget.onAccept != null)
                      GestureDetector(
                        onTap: () {
                          widget.onAccept?.call();
                          _dismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text('Accept',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                    const SizedBox(width: 6),
                    // Dismiss X
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ).animate().shimmer(delay: 400.ms, duration: 1200.ms, color: AppColors.primary.withValues(alpha: 0.06)),
            ),
          ),
        ),
      ),
    );
  }
}
