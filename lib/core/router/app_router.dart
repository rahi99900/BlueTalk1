import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/home/presentation/pages/home_page.dart';

import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/join_group.dart';
import '../../features/groups/presentation/pages/join_group_preview_page.dart';
import '../../features/friends/presentation/pages/add_friends_page.dart';
import '../../features/friends/presentation/pages/qr_scanner_page.dart';
import '../../features/voice_room/presentation/pages/voice_room_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupsPage(),
        ),

        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),

    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/group/:id',
      builder: (context, state) => GroupDetailPage(
        groupId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/add-friends',
      builder: (context, state) => const AddFriendsPage(),
    ),
    GoRoute(
      path: '/join-group',
      builder: (context, state) => const JoinGroupPage(),
    ),
    GoRoute(
      path: '/join-group-preview/:id',
      builder: (context, state) => JoinGroupPreviewPage(
        groupId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const QrScannerPage(),
    ),
    GoRoute(
      path: '/voice-room/:id',
      builder: (context, state) => VoiceRoomPage(
        roomId: state.pathParameters['id'] ?? '',
        roomName: state.uri.queryParameters['name'] ?? 'Voice Room',
      ),
    ),
  ],
);
