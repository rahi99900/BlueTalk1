import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/friends_provider.dart';
import '../../core/services/friends_repository.dart';


import '../../features/voice_room/presentation/pages/voice_room_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'in_app_notification.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  // Track shown notification IDs to avoid repeating
  final Set<String> _shownRequestIds = {};

  final List<_NavItem> _navItems = const [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, path: '/home'),
    _NavItem(label: 'Groups', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, path: '/groups'),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, path: '/profile'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) {
        _currentIndex = i;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomState = VoiceRoomState.instance;
    final isInRoom = roomState.activeRoomId != null;

    // Listen to pending friend requests and show in-app notification for new ones
    ref.listen<AsyncValue<List<dynamic>>>(pendingRequestsProvider, (prev, next) {
      next.whenData((requests) {
        final prevList = prev?.valueOrNull ?? [];
        if (requests.length > prevList.length) {
          // New request arrived!
          final newRequests = requests.where((u) {
            final id = u.id as String;
            return !_shownRequestIds.contains(id) &&
                !prevList.any((p) => p.id == id);
          }).toList();

          for (final user in newRequests) {
            _shownRequestIds.add(user.id as String);
            final senderName = (user.displayName?.isNotEmpty == true
                    ? user.displayName
                    : user.username) ??
                'Someone';
            if (!mounted) return;
            InAppNotificationOverlay.show(
              context,
              senderName: senderName as String,
              message: '$senderName sent you a friend request',
              onAccept: () async {
                await ref
                    .read(friendsRepositoryProvider)
                    .acceptRequest(user.id as String);
              },
              onTap: () => context.push('/add-friends'),
            );
          }
        }
      });
    });

    final pendingCount = ref.watch(pendingRequestsCountProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mini-player bar ──
          if (isInRoom)
            GestureDetector(
              onTap: () => context.push(
                '/voice-room/${roomState.activeRoomId}?name=${Uri.encodeComponent(roomState.activeRoomName ?? '')}',
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  roomState.activeRoomName ?? 'Voice Room',
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.onlineGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.onlineGreen.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)],
                                ),
                              ),
                            ],
                          ),
                          Text('Tap to return',
                              style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        VoiceRoomState.instance.leaveRoom();
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Leave',
                          style: GoogleFonts.inter(
                            color: AppColors.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Nav Bar ──
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isActive = _currentIndex == i;
                    
                    bool showBadge = false;
                    if (i == 0 && pendingCount > 0) showBadge = true; // Home (Add friends requests)

                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = i);
                        context.go(item.path);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: isActive
                            ? BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20))
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon with badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  color: isActive
                                      ? AppColors.primary
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  size: 24,
                                ),
                                if (showBadge)
                                  Positioned(
                                    top: -3, right: -4,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? AppColors.backgroundDark : Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _NavItem({
    required this.label, required this.icon,
    required this.activeIcon, required this.path,
  });
}
